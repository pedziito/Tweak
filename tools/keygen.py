#!/usr/bin/env python3
"""
Tweak License Key Generator

Generates license keys, encrypts them, and pushes to a private GitHub repo.
Requires: pip install requests

Usage:
    python keygen.py generate 5          # Generate 5 new keys
    python keygen.py list                 # List all licenses
    python keygen.py revoke LICENSE-XXXX  # Revoke a license key
    python keygen.py init                 # Initialize the license repo file
"""

import argparse
import base64
import hashlib
import json
import os
import random
import string
import sys
from datetime import datetime, timezone

try:
    import requests
except ImportError:
    print("Error: pip install requests")
    sys.exit(1)

# ── Configuration ──
GITHUB_OWNER = "pedziito"
GITHUB_REPO  = "tweak-licenses"
LICENSE_FILE = "licenses.enc"

# Must match the XOR key in LicenseManager.cpp exactly!
XOR_KEY = bytes([
    0x54, 0x77, 0x65, 0x61, 0x6B, 0x4C, 0x69, 0x63,
    0x65, 0x6E, 0x73, 0x65, 0x4B, 0x65, 0x79, 0x21,
    0xAB, 0xCD, 0xEF, 0x01, 0x23, 0x45, 0x67, 0x89,
    0xDE, 0xAD, 0xBE, 0xEF, 0xCA, 0xFE, 0xBA, 0xBE,
])


def get_token():
    """Get GitHub token from environment or .env file."""
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        return token
    env_file = os.path.join(os.path.dirname(__file__), ".env")
    if os.path.exists(env_file):
        with open(env_file) as f:
            for line in f:
                line = line.strip()
                if line.startswith("GITHUB_TOKEN="):
                    return line.split("=", 1)[1].strip().strip('"').strip("'")
    print("Error: Set GITHUB_TOKEN env var or create tools/.env with GITHUB_TOKEN=...")
    sys.exit(1)


def encrypt(data: bytes) -> bytes:
    """XOR encrypt then base64 encode."""
    xored = bytes(b ^ XOR_KEY[i % len(XOR_KEY)] for i, b in enumerate(data))
    return base64.b64encode(xored)


def decrypt(data: bytes) -> bytes:
    """Base64 decode then XOR decrypt."""
    raw = base64.b64decode(data)
    return bytes(b ^ XOR_KEY[i % len(XOR_KEY)] for i, b in enumerate(raw))


def github_headers(token):
    return {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github.v3+json",
        "User-Agent": "Tweak-Keygen",
    }


def fetch_licenses(token):
    """Fetch and decrypt licenses from GitHub."""
    url = f"https://api.github.com/repos/{GITHUB_OWNER}/{GITHUB_REPO}/contents/{LICENSE_FILE}"
    resp = requests.get(url, headers=github_headers(token))

    if resp.status_code == 404:
        return [], None  # File doesn't exist yet

    resp.raise_for_status()
    data = resp.json()
    sha = data["sha"]
    content = base64.b64decode(data["content"])
    decrypted = decrypt(content)
    licenses = json.loads(decrypted)
    return licenses, sha


def save_licenses(token, licenses, sha=None):
    """Encrypt and save licenses to GitHub."""
    url = f"https://api.github.com/repos/{GITHUB_OWNER}/{GITHUB_REPO}/contents/{LICENSE_FILE}"
    json_data = json.dumps(licenses, indent=2).encode()
    encrypted = encrypt(json_data)

    body = {
        "message": f"Update licenses ({datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M')})",
        "content": base64.b64encode(encrypted).decode(),
    }
    if sha:
        body["sha"] = sha

    resp = requests.put(url, headers=github_headers(token), json=body)
    resp.raise_for_status()
    print(f"Saved {len(licenses)} license(s) to GitHub.")


def generate_key():
    """Generate a random license key in format LICENSE-XXXX-XXXX-XXXX."""
    chars = string.ascii_uppercase + string.digits
    segments = ["".join(random.choices(chars, k=4)) for _ in range(3)]
    return "LICENSE-" + "-".join(segments)


def cmd_generate(args):
    token = get_token()
    licenses, sha = fetch_licenses(token)
    existing_keys = {lic["key"] for lic in licenses}

    new_keys = []
    for _ in range(args.count):
        while True:
            key = generate_key()
            if key not in existing_keys:
                break
        existing_keys.add(key)
        license_entry = {
            "key": key,
            "hwid": "",
            "username": "",
            "password": "",
            "created_at": datetime.now(timezone.utc).isoformat(),
            "activated_at": "",
        }
        licenses.append(license_entry)
        new_keys.append(key)

    save_licenses(token, licenses, sha)

    print(f"\nGenerated {len(new_keys)} new license key(s):\n")
    for k in new_keys:
        print(f"  {k}")
    print()


def cmd_list(args):
    token = get_token()
    licenses, _ = fetch_licenses(token)

    if not licenses:
        print("No licenses found.")
        return

    print(f"\n{'Key':<28} {'HWID':<34} {'Username':<16} {'Created':<22} {'Activated'}")
    print("-" * 130)
    for lic in licenses:
        hwid = lic.get("hwid", "") or "—"
        user = lic.get("username", "") or "—"
        created = lic.get("created_at", "")[:19] or "—"
        activated = lic.get("activated_at", "")[:19] or "—"
        print(f"  {lic['key']:<26} {hwid:<34} {user:<16} {created:<22} {activated}")
    print(f"\nTotal: {len(licenses)} license(s)\n")


def cmd_revoke(args):
    token = get_token()
    licenses, sha = fetch_licenses(token)

    key_upper = args.key.upper()
    found = False
    new_licenses = []
    for lic in licenses:
        if lic["key"].upper() == key_upper:
            found = True
            print(f"Revoked: {lic['key']}")
            if lic.get("username"):
                print(f"  Was bound to user: {lic['username']}")
        else:
            new_licenses.append(lic)

    if not found:
        print(f"Key not found: {args.key}")
        return

    save_licenses(token, new_licenses, sha)


def cmd_init(args):
    token = get_token()
    try:
        licenses, _ = fetch_licenses(token)
        if licenses:
            print(f"License database already exists with {len(licenses)} license(s).")
            return
    except Exception:
        pass

    save_licenses(token, [])
    print("Initialized empty license database.")


def main():
    parser = argparse.ArgumentParser(description="Tweak License Key Manager")
    sub = parser.add_subparsers(dest="command")

    gen = sub.add_parser("generate", help="Generate new license keys")
    gen.add_argument("count", type=int, default=1, nargs="?", help="Number of keys to generate")

    sub.add_parser("list", help="List all licenses")

    rev = sub.add_parser("revoke", help="Revoke a license key")
    rev.add_argument("key", help="License key to revoke")

    sub.add_parser("init", help="Initialize the license database")

    args = parser.parse_args()

    if args.command == "generate":
        cmd_generate(args)
    elif args.command == "list":
        cmd_list(args)
    elif args.command == "revoke":
        cmd_revoke(args)
    elif args.command == "init":
        cmd_init(args)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
