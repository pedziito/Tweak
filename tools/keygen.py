#!/usr/bin/env python3
"""
Tweak License Admin Panel — localhost web UI

Manage license keys: generate, revoke, reset HWID, view users.
Requires: pip install flask requests

Usage:
    python keygen.py                     # Start on http://localhost:5000
    python keygen.py --port 8080         # Custom port
"""

import argparse
import base64
import json
import os
import random
import string
import sys
from datetime import datetime, timezone

try:
    from flask import Flask, request, jsonify, Response
except ImportError:
    print("Error: pip install flask"); sys.exit(1)
try:
    import requests as http
except ImportError:
    print("Error: pip install requests"); sys.exit(1)

# ── Configuration ──
GITHUB_OWNER = "pedziito"
GITHUB_REPO  = "tweak-licenses"
LICENSE_FILE = "licenses.enc"

XOR_KEY = bytes([
    0x54, 0x77, 0x65, 0x61, 0x6B, 0x4C, 0x69, 0x63,
    0x65, 0x6E, 0x73, 0x65, 0x4B, 0x65, 0x79, 0x21,
    0xAB, 0xCD, 0xEF, 0x01, 0x23, 0x45, 0x67, 0x89,
    0xDE, 0xAD, 0xBE, 0xEF, 0xCA, 0xFE, 0xBA, 0xBE,
])

def get_token():
    # .env file takes priority over environment (Codespaces sets its own GITHUB_TOKEN)
    env_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")
    if os.path.exists(env_file):
        with open(env_file) as f:
            for line in f:
                line = line.strip()
                if line.startswith("GITHUB_TOKEN="):
                    return line.split("=", 1)[1].strip().strip('"').strip("'")
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        return token
    return None

def encrypt(data: bytes) -> bytes:
    xored = bytes(b ^ XOR_KEY[i % len(XOR_KEY)] for i, b in enumerate(data))
    return base64.b64encode(xored)

def decrypt(data: bytes) -> bytes:
    raw = base64.b64decode(data)
    return bytes(b ^ XOR_KEY[i % len(XOR_KEY)] for i, b in enumerate(raw))

def gh_headers(token):
    return {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github.v3+json",
        "User-Agent": "Tweak-Admin",
    }

def fetch_licenses(token):
    url = f"https://api.github.com/repos/{GITHUB_OWNER}/{GITHUB_REPO}/contents/{LICENSE_FILE}"
    r = http.get(url, headers=gh_headers(token))
    if r.status_code == 404:
        return [], None
    r.raise_for_status()
    d = r.json()
    content = base64.b64decode(d["content"])
    decrypted = decrypt(content)
    return json.loads(decrypted), d["sha"]

def save_licenses(token, licenses, sha=None):
    url = f"https://api.github.com/repos/{GITHUB_OWNER}/{GITHUB_REPO}/contents/{LICENSE_FILE}"
    encrypted = encrypt(json.dumps(licenses, indent=2).encode())
    body = {
        "message": f"Update licenses ({datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M')})",
        "content": base64.b64encode(encrypted).decode(),
    }
    if sha:
        body["sha"] = sha
    r = http.put(url, headers=gh_headers(token), json=body)
    r.raise_for_status()

def generate_key():
    chars = string.ascii_uppercase + string.digits
    return "LICENSE-" + "-".join("".join(random.choices(chars, k=4)) for _ in range(3))

# ══════════════════════ Flask App ══════════════════════

app = Flask(__name__)

@app.route("/")
def index():
    return Response(HTML_PAGE, content_type="text/html")

@app.route("/api/licenses")
def api_list():
    token = get_token()
    if not token:
        return jsonify({"error": "No GITHUB_TOKEN set"}), 500
    try:
        licenses, sha = fetch_licenses(token)
        return jsonify({"licenses": licenses, "sha": sha})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/generate", methods=["POST"])
def api_generate():
    token = get_token()
    if not token:
        return jsonify({"error": "No GITHUB_TOKEN"}), 500
    count = request.json.get("count", 1)
    try:
        licenses, sha = fetch_licenses(token)
        existing = {l["key"] for l in licenses}
        new_keys = []
        for _ in range(count):
            while True:
                k = generate_key()
                if k not in existing:
                    break
            existing.add(k)
            licenses.append({
                "key": k, "hwid": "", "username": "", "password": "",
                "created_at": datetime.now(timezone.utc).isoformat(), "activated_at": "",
            })
            new_keys.append(k)
        save_licenses(token, licenses, sha)
        return jsonify({"ok": True, "keys": new_keys})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/revoke", methods=["POST"])
def api_revoke():
    token = get_token()
    if not token:
        return jsonify({"error": "No GITHUB_TOKEN"}), 500
    key = request.json.get("key", "").upper()
    try:
        licenses, sha = fetch_licenses(token)
        new_list = [l for l in licenses if l["key"].upper() != key]
        if len(new_list) == len(licenses):
            return jsonify({"error": "Key not found"}), 404
        save_licenses(token, new_list, sha)
        return jsonify({"ok": True})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/reset-hwid", methods=["POST"])
def api_reset_hwid():
    token = get_token()
    if not token:
        return jsonify({"error": "No GITHUB_TOKEN"}), 500
    key = request.json.get("key", "").upper()
    try:
        licenses, sha = fetch_licenses(token)
        found = False
        for l in licenses:
            if l["key"].upper() == key:
                l["hwid"] = ""
                l["activated_at"] = ""
                found = True
                break
        if not found:
            return jsonify({"error": "Key not found"}), 404
        save_licenses(token, licenses, sha)
        return jsonify({"ok": True})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/reset-user", methods=["POST"])
def api_reset_user():
    token = get_token()
    if not token:
        return jsonify({"error": "No GITHUB_TOKEN"}), 500
    key = request.json.get("key", "").upper()
    try:
        licenses, sha = fetch_licenses(token)
        found = False
        for l in licenses:
            if l["key"].upper() == key:
                l["hwid"] = ""
                l["username"] = ""
                l["password"] = ""
                l["activated_at"] = ""
                found = True
                break
        if not found:
            return jsonify({"error": "Key not found"}), 404
        save_licenses(token, licenses, sha)
        return jsonify({"ok": True})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/init", methods=["POST"])
def api_init():
    token = get_token()
    if not token:
        return jsonify({"error": "No GITHUB_TOKEN"}), 500
    try:
        licenses, sha = fetch_licenses(token)
        if licenses:
            return jsonify({"error": f"Database already has {len(licenses)} license(s)"}), 400
    except Exception:
        sha = None
    try:
        save_licenses(token, [], sha)
        return jsonify({"ok": True})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ══════════════════════ HTML ══════════════════════

HTML_PAGE = r"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Tweak License Admin</title>
<style>
*,*::before,*::after{margin:0;padding:0;box-sizing:border-box}
:root{--bg:#060a14;--bg2:#0b1022;--bg3:#111827;--border:#1a2240;--cyan:#06b6d4;--cyan2:#0891b2;--green:#10b981;--red:#ef4444;--amber:#f59e0b;--purple:#8b5cf6;--text:#f1f5f9;--text2:#94a3b8;--text3:#4b5e80;--radius:14px}
html,body{height:100%;font-family:'Segoe UI',system-ui,sans-serif;background:var(--bg);color:var(--text)}
::-webkit-scrollbar{width:5px}::-webkit-scrollbar-track{background:transparent}::-webkit-scrollbar-thumb{background:var(--border);border-radius:3px}

.container{max-width:1100px;margin:0 auto;padding:32px 28px}
.header{display:flex;align-items:center;justify-content:space-between;margin-bottom:32px}
.header h1{font-size:28px;font-weight:800;background:linear-gradient(135deg,var(--cyan),var(--purple));-webkit-background-clip:text;background-clip:text;-webkit-text-fill-color:transparent}
.header .sub{font-size:13px;color:var(--text3);margin-top:4px}
.header-right{display:flex;gap:10px;align-items:center}

.stats{display:grid;grid-template-columns:repeat(4,1fr);gap:14px;margin-bottom:28px}
.stat{background:var(--bg2);border:1px solid var(--border);border-radius:var(--radius);padding:22px;text-align:center}
.stat .val{font-size:30px;font-weight:900;background:linear-gradient(135deg,var(--cyan),var(--purple));-webkit-background-clip:text;background-clip:text;-webkit-text-fill-color:transparent}
.stat .lbl{font-size:10px;color:var(--text3);text-transform:uppercase;letter-spacing:1px;font-weight:700;margin-top:4px}

.card{background:var(--bg2);border:1px solid var(--border);border-radius:var(--radius);padding:24px;margin-bottom:20px}
.card-title{font-size:11px;font-weight:700;color:var(--text3);text-transform:uppercase;letter-spacing:1.2px;margin-bottom:16px}

.btn{display:inline-flex;align-items:center;gap:7px;padding:10px 20px;border-radius:10px;border:none;font-size:13px;font-weight:600;cursor:pointer;transition:all .2s;white-space:nowrap}
.btn:disabled{opacity:.5;cursor:not-allowed}
.btn-cyan{background:var(--cyan);color:#000}.btn-cyan:hover:not(:disabled){background:var(--cyan2);transform:translateY(-1px)}
.btn-red{background:rgba(239,68,68,.15);color:var(--red);border:1px solid rgba(239,68,68,.2)}.btn-red:hover:not(:disabled){background:rgba(239,68,68,.25)}
.btn-amber{background:rgba(245,158,11,.12);color:var(--amber);border:1px solid rgba(245,158,11,.2)}.btn-amber:hover:not(:disabled){background:rgba(245,158,11,.22)}
.btn-outline{background:transparent;border:1px solid var(--border);color:var(--text2)}.btn-outline:hover:not(:disabled){border-color:var(--cyan);color:var(--cyan)}
.btn-green{background:rgba(16,185,129,.12);color:var(--green);border:1px solid rgba(16,185,129,.2)}.btn-green:hover:not(:disabled){background:rgba(16,185,129,.22)}
.btn-sm{padding:7px 14px;font-size:12px;border-radius:8px}

.gen-bar{display:flex;gap:10px;align-items:center;margin-bottom:6px}
.gen-bar input[type=number]{width:80px;padding:10px 14px;border-radius:10px;border:1px solid var(--border);background:var(--bg3);color:var(--text);font-size:14px;outline:none;text-align:center}
.gen-bar input:focus{border-color:var(--cyan);box-shadow:0 0 0 3px rgba(6,182,212,.1)}

table{width:100%;border-collapse:collapse}
th{font-size:10px;font-weight:700;color:var(--text3);text-transform:uppercase;letter-spacing:.8px;text-align:left;padding:10px 12px;border-bottom:1px solid var(--border)}
td{padding:12px;font-size:13px;border-bottom:1px solid rgba(26,34,64,.5);vertical-align:middle}
tr:hover td{background:rgba(255,255,255,.02)}
.key-cell{font-family:'Cascadia Code','Fira Code',monospace;font-weight:600;color:var(--cyan);font-size:13px;letter-spacing:.5px}
.hwid-cell{font-family:monospace;font-size:11px;color:var(--text2);max-width:200px;overflow:hidden;text-overflow:ellipsis}
.user-cell{font-weight:600;color:var(--text)}
.date-cell{font-size:12px;color:var(--text3)}
.status-badge{display:inline-block;padding:3px 10px;border-radius:20px;font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.5px}
.status-active{background:rgba(16,185,129,.12);color:var(--green)}
.status-unused{background:rgba(6,182,212,.1);color:var(--cyan)}
.actions-cell{display:flex;gap:6px;flex-wrap:wrap}
.empty{text-align:center;padding:40px;color:var(--text3);font-size:14px}

.toast{position:fixed;bottom:24px;right:24px;padding:14px 24px;border-radius:12px;font-size:13px;font-weight:600;z-index:999;box-shadow:0 12px 40px rgba(0,0,0,.5);animation:slideUp .3s ease;max-width:400px}
.toast-ok{background:var(--bg2);border:1px solid rgba(16,185,129,.3);color:var(--green)}
.toast-err{background:var(--bg2);border:1px solid rgba(239,68,68,.3);color:var(--red)}
@keyframes slideUp{from{transform:translateY(20px);opacity:0}to{transform:translateY(0);opacity:1}}

.loading{display:inline-block;width:16px;height:16px;border:2px solid var(--border);border-top-color:var(--cyan);border-radius:50%;animation:spin .6s linear infinite}
@keyframes spin{to{transform:rotate(360deg)}}

.new-keys{margin-top:12px;display:flex;flex-wrap:wrap;gap:8px}
.new-key{background:var(--bg3);border:1px solid rgba(6,182,212,.2);border-radius:8px;padding:6px 14px;font-family:monospace;font-size:13px;color:var(--cyan);letter-spacing:.5px;cursor:pointer;transition:all .2s}
.new-key:hover{background:rgba(6,182,212,.1);border-color:var(--cyan)}
.new-key:active{transform:scale(.97)}

@media(max-width:800px){.stats{grid-template-columns:repeat(2,1fr)}}
</style>
</head>
<body>
<div class="container" id="app">
  <div class="header">
    <div>
      <h1>Tweak License Admin</h1>
      <div class="sub">Manage license keys, users & HWID bindings</div>
    </div>
    <div class="header-right">
      <button class="btn btn-outline" onclick="loadLicenses()" id="refreshBtn">Refresh</button>
      <button class="btn btn-outline" onclick="initDb()" id="initBtn">Init DB</button>
    </div>
  </div>

  <div class="stats">
    <div class="stat"><div class="val" id="statTotal">—</div><div class="lbl">Total Keys</div></div>
    <div class="stat"><div class="val" id="statActive">—</div><div class="lbl">Activated</div></div>
    <div class="stat"><div class="val" id="statUnused">—</div><div class="lbl">Unused</div></div>
    <div class="stat"><div class="val" id="statBound">—</div><div class="lbl">HWID Bound</div></div>
  </div>

  <div class="card">
    <div class="card-title">Generate Keys</div>
    <div class="gen-bar">
      <input type="number" id="genCount" value="1" min="1" max="50">
      <button class="btn btn-cyan" onclick="generateKeys()" id="genBtn">Generate</button>
    </div>
    <div class="new-keys" id="newKeys"></div>
  </div>

  <div class="card">
    <div class="card-title">All Licenses</div>
    <div style="margin-bottom:14px">
      <input type="text" id="searchInput" placeholder="Search by key or username..." oninput="renderTable()" style="width:100%;padding:10px 14px;border-radius:10px;border:1px solid var(--border);background:var(--bg3);color:var(--text);font-size:13px;outline:none">
    </div>
    <div id="tableWrap">
      <div class="empty"><span class="loading"></span> Loading...</div>
    </div>
  </div>
</div>

<!-- Toast -->
<div id="toast" style="display:none"></div>

<script>
let licenses = [];

function toast(msg, ok = true) {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.className = 'toast ' + (ok ? 'toast-ok' : 'toast-err');
  t.style.display = 'block';
  clearTimeout(t._timer);
  t._timer = setTimeout(() => t.style.display = 'none', 3500);
}

async function api(path, method = 'GET', body = null) {
  const opts = { method, headers: { 'Content-Type': 'application/json' } };
  if (body) opts.body = JSON.stringify(body);
  const r = await fetch(path, opts);
  const d = await r.json();
  if (!r.ok) throw new Error(d.error || 'Request failed');
  return d;
}

function updateStats() {
  document.getElementById('statTotal').textContent = licenses.length;
  document.getElementById('statActive').textContent = licenses.filter(l => l.username).length;
  document.getElementById('statUnused').textContent = licenses.filter(l => !l.username).length;
  document.getElementById('statBound').textContent = licenses.filter(l => l.hwid).length;
}

function renderTable() {
  updateStats();
  const query = (document.getElementById('searchInput')?.value || '').toLowerCase();
  const filtered = query ? licenses.filter(l => l.key.toLowerCase().includes(query) || (l.username || '').toLowerCase().includes(query)) : licenses;
  if (filtered.length === 0) {
    document.getElementById('tableWrap').innerHTML = query ? '<div class="empty">No matches found</div>' : '<div class="empty">No licenses yet. Generate some!</div>';
    return;
  }
  let html = `<table><thead><tr>
    <th>License Key</th><th>Status</th><th>Username</th><th>HWID</th><th>Created</th><th>Activated</th><th>Actions</th>
  </tr></thead><tbody>`;
  for (const l of filtered) {
    const active = !!l.username;
    const hwid = l.hwid || '—';
    const user = l.username || '—';
    const created = l.created_at ? l.created_at.substring(0, 10) : '—';
    const activated = l.activated_at ? l.activated_at.substring(0, 10) : '—';
    html += `<tr>
      <td class="key-cell">${esc(l.key)}</td>
      <td><span class="status-badge ${active ? 'status-active' : 'status-unused'}">${active ? 'Active' : 'Unused'}</span></td>
      <td class="user-cell">${esc(user)}</td>
      <td class="hwid-cell" title="${esc(hwid)}">${esc(hwid)}</td>
      <td class="date-cell">${esc(created)}</td>
      <td class="date-cell">${esc(activated)}</td>
      <td><div class="actions-cell">
        ${l.hwid ? `<button class="btn btn-amber btn-sm" onclick="resetHwid('${esc(l.key)}')">Reset HWID</button>` : ''}
        ${l.username ? `<button class="btn btn-outline btn-sm" onclick="resetUser('${esc(l.key)}')">Reset User</button>` : ''}
        <button class="btn btn-red btn-sm" onclick="revoke('${esc(l.key)}')">Revoke</button>
      </div></td>
    </tr>`;
  }
  html += '</tbody></table>';
  document.getElementById('tableWrap').innerHTML = html;
}

function esc(s) { const d = document.createElement('div'); d.textContent = s; return d.innerHTML; }

async function loadLicenses() {
  try {
    document.getElementById('tableWrap').innerHTML = '<div class="empty"><span class="loading"></span> Loading...</div>';
    const d = await api('/api/licenses');
    licenses = d.licenses || [];
    renderTable();
  } catch (e) { toast(e.message, false); }
}

async function generateKeys() {
  const n = parseInt(document.getElementById('genCount').value) || 1;
  const btn = document.getElementById('genBtn');
  btn.disabled = true; btn.innerHTML = '<span class="loading"></span> Generating...';
  try {
    const d = await api('/api/generate', 'POST', { count: n });
    toast(`Generated ${d.keys.length} key(s)`);
    // Show new keys
    const wrap = document.getElementById('newKeys');
    wrap.innerHTML = d.keys.map(k => `<div class="new-key" onclick="navigator.clipboard.writeText('${k}');toast('Copied!')" title="Click to copy">${k}</div>`).join('');
    await loadLicenses();
  } catch (e) { toast(e.message, false); }
  btn.disabled = false; btn.innerHTML = 'Generate';
}

async function revoke(key) {
  if (!confirm(`Revoke license ${key}? This cannot be undone.`)) return;
  try {
    await api('/api/revoke', 'POST', { key });
    toast(`Revoked ${key}`);
    await loadLicenses();
  } catch (e) { toast(e.message, false); }
}

async function resetHwid(key) {
  if (!confirm(`Reset HWID for ${key}? The user will need to re-activate.`)) return;
  try {
    await api('/api/reset-hwid', 'POST', { key });
    toast(`HWID reset for ${key}`);
    await loadLicenses();
  } catch (e) { toast(e.message, false); }
}

async function resetUser(key) {
  if (!confirm(`Reset user + HWID for ${key}? The key becomes fully unused.`)) return;
  try {
    await api('/api/reset-user', 'POST', { key });
    toast(`User reset for ${key}`);
    await loadLicenses();
  } catch (e) { toast(e.message, false); }
}

async function initDb() {
  try {
    await api('/api/init', 'POST');
    toast('Database initialized');
    await loadLicenses();
  } catch (e) { toast(e.message, false); }
}

// Load on start
loadLicenses();
</script>
</body>
</html>"""

# ══════════════════════ Main ══════════════════════

def main():
    parser = argparse.ArgumentParser(description="Tweak License Admin Panel")
    parser.add_argument("--port", type=int, default=5000, help="Port (default 5000)")
    parser.add_argument("--host", default="127.0.0.1", help="Host (default 127.0.0.1)")
    args = parser.parse_args()

    token = get_token()
    if not token:
        print("WARNING: No GITHUB_TOKEN found!")
        print("Set GITHUB_TOKEN env var or create tools/.env with GITHUB_TOKEN=...")
        print()

    print(f"\n  Tweak License Admin → http://{args.host}:{args.port}\n")
    app.run(host=args.host, port=args.port, debug=False)

if __name__ == "__main__":
    main()
