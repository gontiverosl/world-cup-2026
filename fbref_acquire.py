"""
fbref_acquire.py — ACQUIRE node: fetch FBref match pages as raw HTML via Firecrawl.

Replaces the dead Chrome/fbref_move.py step (Chrome uninstalled 2026-07-08).

Usage:
    python3 fbref_acquire.py <url-or-hex> [<url-or-hex> ...]
    python3 fbref_acquire.py --out-dir /tmp/spike <url>   # §0 spike: don't touch results/raw/

Rule footnote: this script uses `requests` against api.firecrawl.dev ONLY.
That does not violate the repo's "never requests/curl/httpx" rule — that rule is
about hitting fbref.com directly (403s). Firecrawl performs the FBref fetch; this
script only talks to Firecrawl's API. No LLM extraction — raw HTML only.
"""

import os
import sys
import logging
import requests

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ENV_PATH = os.path.join(BASE_DIR, ".env")
RAW_DIR = os.path.join(BASE_DIR, "results", "raw")
LOG_PATH = os.path.join(BASE_DIR, "worldcup26.log")

API_URL = os.environ.get("FIRECRAWL_API_URL", "https://api.firecrawl.dev/v2/scrape")
WAIT_MS = 3000
TIMEOUT_MS = 60000

logging.basicConfig(
    filename=LOG_PATH,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
)


def load_env():
    """Minimal .env reader — python-dotenv isn't installed and this needs one key."""
    if not os.path.exists(ENV_PATH):
        return
    with open(ENV_PATH, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, val = line.partition("=")
            os.environ.setdefault(key.strip(), val.strip().strip("'\""))


def to_url(source):
    """Accept a full FBref match URL or a bare hex; return a fetchable URL."""
    if source.startswith("http"):
        return source
    return f"https://fbref.com/en/matches/{source}"


def to_hex(source):
    """Extract the FBref match hex — the pipeline's join key — from a URL or bare hex."""
    if "/matches/" in source:
        return source.split("/matches/")[1].split("/")[0]
    return source


def fetch_html(url, api_key):
    """Firecrawl scrape → rendered HTML string, or None on failure (skip + log, never partial)."""
    payload = {
        "url": url,
        "formats": ["html"],
        "onlyMainContent": False,  # main-content extraction would strip the stat tables
        "proxy": "auto",
        "waitFor": WAIT_MS,
        "timeout": TIMEOUT_MS,
    }
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}

    try:
        resp = requests.post(API_URL, json=payload, headers=headers, timeout=120)
    except requests.RequestException as e:
        logging.error(f"Firecrawl request failed for {url}: {e}")
        return None

    if resp.status_code != 200:
        logging.error(f"Firecrawl HTTP {resp.status_code} for {url}: {resp.text[:300]}")
        return None

    body = resp.json()
    if not body.get("success"):
        logging.error(f"Firecrawl unsuccessful for {url}: {str(body)[:300]}")
        return None

    html = (body.get("data") or {}).get("html")
    if not html:
        logging.error(f"Firecrawl returned no html for {url}")
        return None
    return html


def save_html(html, match_hex, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    path = os.path.join(out_dir, f"{match_hex}.html")
    with open(path, "w", encoding="utf-8") as f:
        f.write(html)
    logging.info(f"acquire: {match_hex} — {len(html)} bytes → {path}")
    return path


def main():
    args = sys.argv[1:]
    out_dir = RAW_DIR
    if "--out-dir" in args:
        i = args.index("--out-dir")
        out_dir = args[i + 1]
        args = args[:i] + args[i + 2 :]

    if not args:
        print("Usage: python3 fbref_acquire.py [--out-dir DIR] <url-or-hex> ...")
        sys.exit(1)

    load_env()
    api_key = os.environ.get("FIRECRAWL_API_KEY")
    if not api_key:
        logging.error("FIRECRAWL_API_KEY not set — cannot acquire.")
        print("FIRECRAWL_API_KEY not set (checked env and .env).")
        sys.exit(1)

    ok, failed = 0, 0
    for source in args:
        match_hex = to_hex(source)
        dest = os.path.join(out_dir, f"{match_hex}.html")
        if os.path.exists(dest):
            print(f"  {match_hex}: already on disk — skipped")
            continue

        print(f"  {match_hex}: fetching...", end=" ", flush=True)
        html = fetch_html(to_url(source), api_key)
        if html is None:
            print("FAILED (see worldcup26.log)")
            failed += 1
            continue

        save_html(html, match_hex, out_dir)
        print(f"ok ({len(html):,} bytes)")
        ok += 1

    print(f"\nAcquire done — {ok} fetched, {failed} failed.")
    logging.info(f"acquire: {ok} fetched, {failed} failed.")
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
