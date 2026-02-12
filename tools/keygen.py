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

@app.route("/api/bulk-revoke", methods=["POST"])
def api_bulk_revoke():
    token = get_token()
    if not token:
        return jsonify({"error": "No GITHUB_TOKEN"}), 500
    keys = request.json.get("keys", [])
    keys = [k.upper() for k in keys]
    if not keys:
        return jsonify({"error": "No keys provided"}), 400
    try:
        licenses, sha = fetch_licenses(token)
        before = len(licenses)
        new_list = [l for l in licenses if l["key"].upper() not in keys]
        removed = before - len(new_list)
        if removed == 0:
            return jsonify({"error": "No matching keys found"}), 404
        save_licenses(token, new_list, sha)
        return jsonify({"ok": True, "removed": removed})
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
:root{--bg:#060a14;--bg2:#0b1022;--bg3:#111827;--bg4:#0d1328;--border:#1a2240;--border2:#1e2d4f;--cyan:#06b6d4;--cyan2:#0891b2;--cyan-glow:rgba(6,182,212,.12);--green:#10b981;--red:#ef4444;--amber:#f59e0b;--purple:#8b5cf6;--text:#f1f5f9;--text2:#94a3b8;--text3:#4b5e80;--radius:14px}
html,body{height:100%;font-family:'Segoe UI',system-ui,sans-serif;background:var(--bg);color:var(--text)}
::-webkit-scrollbar{width:5px}::-webkit-scrollbar-track{background:transparent}::-webkit-scrollbar-thumb{background:var(--border);border-radius:3px}
.icon{width:18px;height:18px;fill:none;stroke:currentColor;stroke-width:1.8;stroke-linecap:round;stroke-linejoin:round;flex-shrink:0;vertical-align:middle}
.icon-sm{width:14px;height:14px}
.icon-lg{width:24px;height:24px}
.icon-xl{width:32px;height:32px}

/* ── Topbar ── */
.topbar{background:var(--bg2);border-bottom:1px solid var(--border);padding:16px 32px;display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;z-index:100;backdrop-filter:blur(16px)}
.topbar-brand{display:flex;align-items:center;gap:14px}
.topbar-logo{width:40px;height:40px;min-width:40px;background:linear-gradient(135deg,var(--cyan),var(--purple));border-radius:12px;display:flex;align-items:center;justify-content:center;box-shadow:0 4px 20px rgba(6,182,212,.25)}
.topbar-logo svg{width:22px;height:22px;stroke:#fff;fill:none;stroke-width:1.8;stroke-linecap:round;stroke-linejoin:round}
.topbar-text h1{font-size:20px;font-weight:800;background:linear-gradient(135deg,var(--cyan),var(--purple));-webkit-background-clip:text;background-clip:text;-webkit-text-fill-color:transparent;line-height:1.2}
.topbar-text span{font-size:11px;color:var(--text3);font-weight:500}
.topbar-actions{display:flex;gap:10px;align-items:center}
.topbar-status{display:flex;align-items:center;gap:6px;padding:6px 14px;border-radius:20px;background:rgba(16,185,129,.08);border:1px solid rgba(16,185,129,.15);font-size:11px;font-weight:600;color:var(--green)}
.topbar-status .dot{width:7px;height:7px;border-radius:50%;background:var(--green);animation:pulse 2s infinite}
@keyframes pulse{0%,100%{opacity:1}50%{opacity:.4}}

.container{max-width:1200px;margin:0 auto;padding:28px 32px}

/* ── Stats ── */
.stats{display:grid;grid-template-columns:repeat(4,1fr);gap:16px;margin-bottom:28px}
.stat{background:var(--bg2);border:1px solid var(--border);border-radius:var(--radius);padding:20px 22px;display:flex;align-items:center;gap:16px;transition:all .25s;position:relative;overflow:hidden}
.stat:hover{border-color:var(--border2);transform:translateY(-2px);box-shadow:0 8px 30px rgba(0,0,0,.3)}
.stat::before{content:'';position:absolute;top:0;left:0;right:0;height:2px;border-radius:var(--radius) var(--radius) 0 0;opacity:0;transition:opacity .25s}
.stat:nth-child(1)::before{background:linear-gradient(90deg,var(--cyan),var(--cyan2));opacity:1}
.stat:nth-child(2)::before{background:linear-gradient(90deg,var(--green),#34d399);opacity:1}
.stat:nth-child(3)::before{background:linear-gradient(90deg,var(--purple),#a78bfa);opacity:1}
.stat:nth-child(4)::before{background:linear-gradient(90deg,var(--amber),#fbbf24);opacity:1}
.stat-icon{width:48px;height:48px;border-radius:12px;display:flex;align-items:center;justify-content:center;flex-shrink:0}
.stat:nth-child(1) .stat-icon{background:rgba(6,182,212,.1);color:var(--cyan)}
.stat:nth-child(2) .stat-icon{background:rgba(16,185,129,.1);color:var(--green)}
.stat:nth-child(3) .stat-icon{background:rgba(139,92,246,.1);color:var(--purple)}
.stat:nth-child(4) .stat-icon{background:rgba(245,158,11,.1);color:var(--amber)}
.stat-info{flex:1}
.stat .val{font-size:28px;font-weight:900;line-height:1.1}
.stat:nth-child(1) .val{color:var(--cyan)}
.stat:nth-child(2) .val{color:var(--green)}
.stat:nth-child(3) .val{color:var(--purple)}
.stat:nth-child(4) .val{color:var(--amber)}
.stat .lbl{font-size:11px;color:var(--text3);text-transform:uppercase;letter-spacing:1px;font-weight:700;margin-top:3px}

/* ── Cards ── */
.card{background:var(--bg2);border:1px solid var(--border);border-radius:var(--radius);padding:24px;margin-bottom:20px;transition:border-color .2s}
.card:hover{border-color:var(--border2)}
.card-header{display:flex;align-items:center;gap:10px;margin-bottom:16px}
.card-header .card-icon{width:32px;height:32px;border-radius:8px;display:flex;align-items:center;justify-content:center;flex-shrink:0}
.card-title{font-size:11px;font-weight:700;color:var(--text3);text-transform:uppercase;letter-spacing:1.2px}
.card-subtitle{font-size:11px;color:var(--text3);margin-top:1px;font-weight:400;text-transform:none;letter-spacing:0}

/* ── Buttons ── */
.btn{display:inline-flex;align-items:center;gap:7px;padding:10px 20px;border-radius:10px;border:none;font-size:13px;font-weight:600;cursor:pointer;transition:all .2s;white-space:nowrap}
.btn:disabled{opacity:.5;cursor:not-allowed}
.btn-cyan{background:var(--cyan);color:#000}.btn-cyan:hover:not(:disabled){background:var(--cyan2);transform:translateY(-1px);box-shadow:0 4px 16px rgba(6,182,212,.3)}
.btn-red{background:rgba(239,68,68,.15);color:var(--red);border:1px solid rgba(239,68,68,.2)}.btn-red:hover:not(:disabled){background:rgba(239,68,68,.25)}
.btn-amber{background:rgba(245,158,11,.12);color:var(--amber);border:1px solid rgba(245,158,11,.2)}.btn-amber:hover:not(:disabled){background:rgba(245,158,11,.22)}
.btn-outline{background:transparent;border:1px solid var(--border);color:var(--text2)}.btn-outline:hover:not(:disabled){border-color:var(--cyan);color:var(--cyan)}
.btn-green{background:rgba(16,185,129,.12);color:var(--green);border:1px solid rgba(16,185,129,.2)}.btn-green:hover:not(:disabled){background:rgba(16,185,129,.22)}
.btn-sm{padding:7px 14px;font-size:12px;border-radius:8px}
.btn-purple{background:rgba(139,92,246,.12);color:var(--purple);border:1px solid rgba(139,92,246,.2)}.btn-purple:hover:not(:disabled){background:rgba(139,92,246,.22)}

/* ── Generate ── */
.gen-bar{display:flex;gap:10px;align-items:center;margin-bottom:6px}
.gen-bar input[type=number]{width:80px;padding:10px 14px;border-radius:10px;border:1px solid var(--border);background:var(--bg3);color:var(--text);font-size:14px;outline:none;text-align:center}
.gen-bar input:focus{border-color:var(--cyan);box-shadow:0 0 0 3px rgba(6,182,212,.1)}
.new-keys{margin-top:12px;display:flex;flex-wrap:wrap;gap:8px}
.new-key{background:var(--bg3);border:1px solid rgba(6,182,212,.2);border-radius:8px;padding:8px 16px;font-family:'Cascadia Code','Fira Code',monospace;font-size:13px;color:var(--cyan);letter-spacing:.5px;cursor:pointer;transition:all .2s;display:flex;align-items:center;gap:8px}
.new-key:hover{background:rgba(6,182,212,.1);border-color:var(--cyan);transform:translateY(-1px)}
.new-key:active{transform:scale(.97)}

/* ── Search ── */
.search-wrap{position:relative;margin-bottom:16px}
.search-wrap .search-icon{position:absolute;left:14px;top:50%;transform:translateY(-50%);color:var(--text3);pointer-events:none}
.search-input{width:100%;padding:11px 14px 11px 42px;border-radius:12px;border:1px solid var(--border);background:var(--bg3);color:var(--text);font-size:13px;outline:none;transition:all .2s}
.search-input:focus{border-color:var(--cyan);box-shadow:0 0 0 3px rgba(6,182,212,.08)}
.search-input::placeholder{color:var(--text3)}

/* ── Table ── */
table{width:100%;border-collapse:collapse}
th{font-size:10px;font-weight:700;color:var(--text3);text-transform:uppercase;letter-spacing:.8px;text-align:left;padding:10px 12px;border-bottom:1px solid var(--border)}
th .icon{margin-right:4px;opacity:.5}
td{padding:12px;font-size:13px;border-bottom:1px solid rgba(26,34,64,.5);vertical-align:middle}
tr:hover td{background:rgba(255,255,255,.02)}
tr.row-selected td{background:rgba(6,182,212,.04)}
.key-cell{font-family:'Cascadia Code','Fira Code',monospace;font-weight:600;color:var(--cyan);font-size:13px;letter-spacing:.5px;display:flex;align-items:center;gap:8px}
.key-cell .icon{color:var(--cyan);opacity:.5}
.hwid-cell{font-family:monospace;font-size:11px;color:var(--text2);max-width:200px;overflow:hidden;text-overflow:ellipsis}
.user-cell{font-weight:600;color:var(--text);display:flex;align-items:center;gap:6px}
.user-cell .icon{color:var(--text3)}
.date-cell{font-size:12px;color:var(--text3)}
.status-badge{display:inline-flex;align-items:center;gap:5px;padding:4px 12px;border-radius:20px;font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.5px}
.status-active{background:rgba(16,185,129,.12);color:var(--green)}
.status-unused{background:rgba(6,182,212,.1);color:var(--cyan)}
.actions-cell{display:flex;gap:4px;flex-wrap:nowrap}
.btn-icon{padding:7px;border-radius:8px;line-height:0}
.btn-icon .icon{width:16px;height:16px}
.empty{text-align:center;padding:48px;color:var(--text3);font-size:14px}
.empty .icon{opacity:.3;margin-bottom:12px}

/* ── Checkbox ── */
.chk{width:16px;height:16px;accent-color:var(--cyan);cursor:pointer;flex-shrink:0}
th .chk{margin-right:4px}
.chk-col{display:none}
.multi-mode .chk-col{display:table-cell}

/* ── Selection Bar ── */
.sel-bar{display:flex;align-items:center;gap:12px;padding:10px 16px;margin-bottom:14px;border-radius:10px;background:rgba(6,182,212,.06);border:1px solid rgba(6,182,212,.15);animation:fadeIn .2s}
.sel-bar .sel-count{font-size:13px;font-weight:600;color:var(--cyan)}
.sel-bar .sel-actions{margin-left:auto;display:flex;gap:8px}

/* ── Multi-select toggle ── */
.multi-bar{display:flex;align-items:center;gap:10px;margin-bottom:14px}
.btn-multi{transition:all .2s}
.btn-multi.active{background:rgba(239,68,68,.15);color:var(--red);border-color:rgba(239,68,68,.2)}

/* ── Footer ── */
.footer{text-align:center;padding:20px;color:var(--text3);font-size:11px;border-top:1px solid var(--border);margin-top:20px}
.footer a{color:var(--cyan);text-decoration:none}

/* ── Toast ── */
.toast{position:fixed;bottom:24px;right:24px;padding:14px 24px;border-radius:12px;font-size:13px;font-weight:600;z-index:999;box-shadow:0 12px 40px rgba(0,0,0,.5);animation:slideUp .3s ease;max-width:400px;display:flex;align-items:center;gap:10px}
.toast-ok{background:var(--bg2);border:1px solid rgba(16,185,129,.3);color:var(--green)}
.toast-err{background:var(--bg2);border:1px solid rgba(239,68,68,.3);color:var(--red)}
@keyframes slideUp{from{transform:translateY(20px);opacity:0}to{transform:translateY(0);opacity:1}}

.loading{display:inline-block;width:16px;height:16px;border:2px solid var(--border);border-top-color:var(--cyan);border-radius:50%;animation:spin .6s linear infinite}
@keyframes spin{to{transform:rotate(360deg)}}

/* ── Confirm Modal ── */
.modal-overlay{position:fixed;inset:0;background:rgba(0,0,0,.6);backdrop-filter:blur(6px);display:flex;align-items:center;justify-content:center;z-index:1000;animation:fadeIn .2s}
.modal{background:var(--bg2);border:1px solid var(--border);border-radius:16px;padding:28px;max-width:420px;width:90%;box-shadow:0 24px 80px rgba(0,0,0,.5)}
.modal h3{font-size:16px;font-weight:700;margin-bottom:8px;display:flex;align-items:center;gap:8px}
.modal p{font-size:13px;color:var(--text2);margin-bottom:20px;line-height:1.5}
.modal-actions{display:flex;gap:10px;justify-content:flex-end}
.modal .key-highlight{background:var(--bg3);padding:2px 8px;border-radius:6px;font-family:monospace;color:var(--cyan);font-size:12px}
@keyframes fadeIn{from{opacity:0}to{opacity:1}}

/* ── Responsive ── */
@media(max-width:900px){.stats{grid-template-columns:repeat(2,1fr)}}
@media(max-width:600px){.stats{grid-template-columns:1fr}.topbar{padding:12px 16px}.container{padding:16px}}
</style>
</head>
<body>

<!-- Topbar -->
<div class="topbar">
  <div class="topbar-brand">
    <div class="topbar-logo">
      <svg viewBox="0 0 24 24"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
    </div>
    <div class="topbar-text">
      <h1>Tweak Admin</h1>
      <span>License Management Console</span>
    </div>
  </div>
  <div class="topbar-actions">
    <div class="topbar-status"><span class="dot"></span> Connected</div>
    <button class="btn btn-outline" onclick="loadLicenses()" id="refreshBtn">
      <svg class="icon" viewBox="0 0 24 24"><polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 1 0 2.13-9.36L1 10"/></svg>
      Refresh
    </button>
    <button class="btn btn-purple" onclick="initDb()" id="initBtn">
      <svg class="icon" viewBox="0 0 24 24"><ellipse cx="12" cy="5" rx="9" ry="3"/><path d="M21 12c0 1.66-4 3-9 3s-9-1.34-9-3"/><path d="M3 5v14c0 1.66 4 3 9 3s9-1.34 9-3V5"/></svg>
      Init DB
    </button>
  </div>
</div>

<div class="container" id="app">

  <!-- Stats -->
  <div class="stats">
    <div class="stat">
      <div class="stat-icon">
        <svg class="icon icon-xl" viewBox="0 0 24 24"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
      </div>
      <div class="stat-info"><div class="val" id="statTotal">—</div><div class="lbl">Total Keys</div></div>
    </div>
    <div class="stat">
      <div class="stat-icon">
        <svg class="icon icon-xl" viewBox="0 0 24 24"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8.5" cy="7" r="4"/><path d="M20 8v6"/><path d="M23 11h-6"/></svg>
      </div>
      <div class="stat-info"><div class="val" id="statActive">—</div><div class="lbl">Activated</div></div>
    </div>
    <div class="stat">
      <div class="stat-icon">
        <svg class="icon icon-xl" viewBox="0 0 24 24"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
      </div>
      <div class="stat-info"><div class="val" id="statUnused">—</div><div class="lbl">Unused</div></div>
    </div>
    <div class="stat">
      <div class="stat-icon">
        <svg class="icon icon-xl" viewBox="0 0 24 24"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
      </div>
      <div class="stat-info"><div class="val" id="statBound">—</div><div class="lbl">HWID Bound</div></div>
    </div>
  </div>

  <!-- Generate Keys -->
  <div class="card">
    <div class="card-header">
      <div class="card-icon" style="background:rgba(6,182,212,.1);color:var(--cyan)">
        <svg class="icon" viewBox="0 0 24 24"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>
      </div>
      <div>
        <div class="card-title">Generate Keys</div>
        <div class="card-subtitle">Create new license keys for distribution</div>
      </div>
    </div>
    <div class="gen-bar">
      <input type="number" id="genCount" value="1" min="1" max="50">
      <button class="btn btn-cyan" onclick="generateKeys()" id="genBtn">
        <svg class="icon icon-sm" viewBox="0 0 24 24"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
        Generate
      </button>
    </div>
    <div class="new-keys" id="newKeys"></div>
  </div>

  <!-- All Licenses -->
  <div class="card">
    <div class="card-header">
      <div class="card-icon" style="background:rgba(139,92,246,.1);color:var(--purple)">
        <svg class="icon" viewBox="0 0 24 24"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
      </div>
      <div>
        <div class="card-title">All Licenses</div>
        <div class="card-subtitle" id="licenseCount">Manage keys, users & HWID bindings</div>
      </div>
    </div>
    <div class="search-wrap">
      <span class="search-icon">
        <svg class="icon" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
      </span>
      <input type="text" id="searchInput" class="search-input" placeholder="Search by key, username or HWID..." oninput="renderTable()">
    </div>
    <div class="multi-bar">
      <button class="btn btn-outline btn-sm btn-multi" id="multiBtn" onclick="toggleMultiMode()">
        <svg class="icon icon-sm" viewBox="0 0 24 24"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
        Revoke Multiple
      </button>
    </div>
    <div id="tableWrap">
      <div class="empty"><span class="loading"></span> Loading...</div>
    </div>
  </div>

  <!-- Footer -->
  <div class="footer">
    <svg class="icon icon-sm" style="vertical-align:middle;margin-right:4px;opacity:.4" viewBox="0 0 24 24"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
    Tweak License Admin &middot; Secure key management &middot; <span id="yearFooter"></span>
  </div>
</div>

<!-- Confirm Modal -->
<div id="confirmModal" class="modal-overlay" style="display:none" onclick="if(event.target===this)closeModal()">
  <div class="modal">
    <h3 id="modalTitle">
      <svg class="icon" viewBox="0 0 24 24"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
      Confirm Action
    </h3>
    <p id="modalMsg">Are you sure?</p>
    <div class="modal-actions">
      <button class="btn btn-outline" onclick="closeModal()">Cancel</button>
      <button class="btn btn-red" id="modalConfirmBtn" onclick="modalAction()">Confirm</button>
    </div>
  </div>
</div>

<!-- Toast -->
<div id="toast" style="display:none"></div>

<script>
let licenses = [];
let pendingAction = null;
let selected = new Set();
let multiMode = false;

document.getElementById('yearFooter').textContent = new Date().getFullYear();

function toast(msg, ok = true) {
  const t = document.getElementById('toast');
  const icon = ok
    ? '<svg class="icon icon-sm" viewBox="0 0 24 24"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>'
    : '<svg class="icon icon-sm" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>';
  t.innerHTML = icon + ' ' + esc(msg);
  t.className = 'toast ' + (ok ? 'toast-ok' : 'toast-err');
  t.style.display = 'flex';
  clearTimeout(t._timer);
  t._timer = setTimeout(() => t.style.display = 'none', 3500);
}

function showModal(title, msg, btnText, btnClass, action) {
  document.getElementById('modalTitle').innerHTML = '<svg class="icon" viewBox="0 0 24 24"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg> ' + esc(title);
  document.getElementById('modalMsg').innerHTML = msg;
  const btn = document.getElementById('modalConfirmBtn');
  btn.textContent = btnText;
  btn.className = 'btn ' + btnClass;
  pendingAction = action;
  document.getElementById('confirmModal').style.display = 'flex';
}
function closeModal() { document.getElementById('confirmModal').style.display = 'none'; pendingAction = null; }
function modalAction() { if (pendingAction) pendingAction(); closeModal(); }

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
  document.getElementById('licenseCount').textContent = licenses.length + ' license(s) in database';
}

function renderTable() {
  updateStats();
  const query = (document.getElementById('searchInput')?.value || '').toLowerCase();
  const filtered = query ? licenses.filter(l =>
    l.key.toLowerCase().includes(query) ||
    (l.username || '').toLowerCase().includes(query) ||
    (l.hwid || '').toLowerCase().includes(query)
  ) : licenses;

  if (filtered.length === 0) {
    document.getElementById('tableWrap').innerHTML = query
      ? '<div class="empty"><svg class="icon" style="width:48px;height:48px;display:block;margin:0 auto 12px" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>No matches found</div>'
      : '<div class="empty"><svg class="icon" style="width:48px;height:48px;display:block;margin:0 auto 12px" viewBox="0 0 24 24"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>No licenses yet. Generate some!</div>';
    return;
  }

  // Selection bar (only in multi mode)
  let selHtml = '';
  if (multiMode && selected.size > 0) {
    selHtml = `<div class="sel-bar">
      <span class="sel-count">${selected.size} selected</span>
      <div class="sel-actions">
        <button class="btn btn-red btn-sm" onclick="bulkRevoke()"><svg class="icon icon-sm" viewBox="0 0 24 24"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg> Revoke Selected</button>
        <button class="btn btn-outline btn-sm" onclick="exitMultiMode()"><svg class="icon icon-sm" viewBox="0 0 24 24"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg> Cancel</button>
      </div>
    </div>`;
  }

  const allKeys = filtered.map(l => l.key);
  const allChecked = allKeys.length > 0 && allKeys.every(k => selected.has(k));

  let html = selHtml + `<table class="${multiMode ? 'multi-mode' : ''}"><thead><tr>
    <th class="chk-col"><input type="checkbox" class="chk" ${allChecked ? 'checked' : ''} onchange="toggleAll(this.checked)"></th>
    <th><svg class="icon icon-sm" viewBox="0 0 24 24"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg> Key</th>
    <th><svg class="icon icon-sm" viewBox="0 0 24 24"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg> Status</th>
    <th><svg class="icon icon-sm" viewBox="0 0 24 24"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg> Username</th>
    <th><svg class="icon icon-sm" viewBox="0 0 24 24"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg> HWID</th>
    <th><svg class="icon icon-sm" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg> Created</th>
    <th><svg class="icon icon-sm" viewBox="0 0 24 24"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg> Activated</th>
    <th>Actions</th>
  </tr></thead><tbody>`;

  for (const l of filtered) {
    const active = !!l.username;
    const hwid = l.hwid || '\u2014';
    const user = l.username || '\u2014';
    const created = l.created_at ? l.created_at.substring(0, 10) : '\u2014';
    const activated = l.activated_at ? l.activated_at.substring(0, 10) : '\u2014';
    const chk = selected.has(l.key) ? 'checked' : '';
    const statusIcon = active
      ? '<svg class="icon icon-sm" viewBox="0 0 24 24"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>'
      : '<svg class="icon icon-sm" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><line x1="8" y1="12" x2="16" y2="12"/></svg>';
    html += `<tr class="${chk ? 'row-selected' : ''}">
      <td class="chk-col"><input type="checkbox" class="chk" ${chk} onchange="toggleSelect('${esc(l.key)}', this.checked)"></td>
      <td class="key-cell"><svg class="icon icon-sm" viewBox="0 0 24 24"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg> ${esc(l.key)}</td>
      <td><span class="status-badge ${active ? 'status-active' : 'status-unused'}">${statusIcon} ${active ? 'Active' : 'Unused'}</span></td>
      <td class="user-cell">${active ? '<svg class="icon icon-sm" viewBox="0 0 24 24"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg> ' : ''}${esc(user)}</td>
      <td class="hwid-cell" title="${esc(hwid)}">${esc(hwid)}</td>
      <td class="date-cell">${esc(created)}</td>
      <td class="date-cell">${esc(activated)}</td>
      <td><div class="actions-cell">
        ${l.hwid ? `<button class="btn btn-amber btn-icon" onclick="resetHwid('${esc(l.key)}')" title="Reset HWID"><svg class="icon" viewBox="0 0 24 24"><polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 1 0 2.13-9.36L1 10"/></svg></button>` : ''}
        ${l.username ? `<button class="btn btn-outline btn-icon" onclick="resetUser('${esc(l.key)}')" title="Reset User"><svg class="icon" viewBox="0 0 24 24"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8.5" cy="7" r="4"/><line x1="23" y1="11" x2="17" y2="11"/></svg></button>` : ''}
        <button class="btn btn-red btn-icon" onclick="revokeKey('${esc(l.key)}')" title="Revoke"><svg class="icon" viewBox="0 0 24 24"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg></button>
      </div></td>
    </tr>`;
  }
  html += '</tbody></table>';
  document.getElementById('tableWrap').innerHTML = html;
}

function esc(s) { const d = document.createElement('div'); d.textContent = String(s); return d.innerHTML; }

async function loadLicenses() {
  const btn = document.getElementById('refreshBtn');
  btn.disabled = true;
  try {
    document.getElementById('tableWrap').innerHTML = '<div class="empty"><span class="loading"></span> Loading...</div>';
    const d = await api('/api/licenses');
    licenses = d.licenses || [];
    renderTable();
  } catch (e) { toast(e.message, false); }
  btn.disabled = false;
}

async function generateKeys() {
  const n = parseInt(document.getElementById('genCount').value) || 1;
  const btn = document.getElementById('genBtn');
  btn.disabled = true; btn.innerHTML = '<span class="loading"></span> Generating...';
  try {
    const d = await api('/api/generate', 'POST', { count: n });
    toast(`Generated ${d.keys.length} key(s)`);
    const wrap = document.getElementById('newKeys');
    wrap.innerHTML = d.keys.map(k => `<div class="new-key" onclick="navigator.clipboard.writeText('${k}');toast('Copied to clipboard!')" title="Click to copy"><svg class="icon icon-sm" viewBox="0 0 24 24"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>${k}</div>`).join('');
    await loadLicenses();
  } catch (e) { toast(e.message, false); }
  btn.disabled = false; btn.innerHTML = '<svg class="icon icon-sm" viewBox="0 0 24 24"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg> Generate';
}

function revokeKey(key) {
  showModal('Revoke License', 'Permanently delete <span class="key-highlight">' + esc(key) + '</span>? This cannot be undone.', 'Revoke', 'btn-red', async () => {
    try { await api('/api/revoke', 'POST', { key }); toast('Revoked ' + key); await loadLicenses(); }
    catch (e) { toast(e.message, false); }
  });
}

function resetHwid(key) {
  showModal('Reset HWID', 'Clear HWID binding for <span class="key-highlight">' + esc(key) + '</span>? The user will need to re-activate on their device.', 'Reset HWID', 'btn-amber', async () => {
    try { await api('/api/reset-hwid', 'POST', { key }); toast('HWID reset for ' + key); await loadLicenses(); }
    catch (e) { toast(e.message, false); }
  });
}

function resetUser(key) {
  showModal('Reset User', 'Clear user & HWID for <span class="key-highlight">' + esc(key) + '</span>? The key becomes completely unused.', 'Reset User', 'btn-red', async () => {
    try { await api('/api/reset-user', 'POST', { key }); toast('User reset for ' + key); await loadLicenses(); }
    catch (e) { toast(e.message, false); }
  });
}

async function initDb() {
  showModal('Initialize Database', 'Create the license database? This only works if no licenses exist yet.', 'Initialize', 'btn-purple', async () => {
    try { await api('/api/init', 'POST'); toast('Database initialized'); await loadLicenses(); }
    catch (e) { toast(e.message, false); }
  });
}

function toggleSelect(key, checked) {
  if (checked) selected.add(key); else selected.delete(key);
  renderTable();
}
function toggleAll(checked) {
  const query = (document.getElementById('searchInput')?.value || '').toLowerCase();
  const filtered = query ? licenses.filter(l => l.key.toLowerCase().includes(query) || (l.username||'').toLowerCase().includes(query) || (l.hwid||'').toLowerCase().includes(query)) : licenses;
  if (checked) filtered.forEach(l => selected.add(l.key)); else selected.clear();
  renderTable();
}
function clearSelection() { selected.clear(); renderTable(); }

function toggleMultiMode() {
  multiMode = !multiMode;
  if (!multiMode) { selected.clear(); }
  document.getElementById('multiBtn').classList.toggle('active', multiMode);
  document.getElementById('multiBtn').innerHTML = multiMode
    ? '<svg class="icon icon-sm" viewBox="0 0 24 24"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg> Cancel'
    : '<svg class="icon icon-sm" viewBox="0 0 24 24"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg> Revoke Multiple';
  renderTable();
}
function exitMultiMode() { multiMode = false; selected.clear(); document.getElementById('multiBtn').classList.remove('active'); document.getElementById('multiBtn').innerHTML = '<svg class="icon icon-sm" viewBox="0 0 24 24"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg> Revoke Multiple'; renderTable(); }

function bulkRevoke() {
  const keys = [...selected];
  showModal('Bulk Revoke', `Permanently delete <strong>${keys.length}</strong> license(s)? This cannot be undone.`, 'Revoke All', 'btn-red', async () => {
    try {
      await api('/api/bulk-revoke', 'POST', { keys });
      toast(`Revoked ${keys.length} license(s)`);
      selected.clear();
      await loadLicenses();
    } catch (e) { toast(e.message, false); }
  });
}

// Keyboard shortcut: Ctrl+K to focus search, Escape to clear selection
document.addEventListener('keydown', e => {
  if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
    e.preventDefault();
    document.getElementById('searchInput').focus();
  }
  if (e.key === 'Escape' && multiMode) {
    exitMultiMode();
  }
  if ((e.ctrlKey || e.metaKey) && e.key === 'a' && multiMode && document.activeElement?.tagName !== 'INPUT') {
    e.preventDefault();
    toggleAll(true);
  }
});

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
