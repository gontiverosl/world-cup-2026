"""Spike: crawl4ai as Firecrawl replacement for FBref raw-HTML acquisition (WC26 node 1).

Run on the Merry (the machine that will do the S7b backfill — bot detection is
IP-dependent, results elsewhere don't transfer).

Setup:
    pip install crawl4ai
    crawl4ai-setup            # installs playwright chromium

Usage:
    python spike_crawl4ai_fbref.py
    python spike_crawl4ai_fbref.py --reference path/to/firecrawl_rawhtml_sample.html

What it verifies:
  1. Whether crawl4ai can fetch FBref at all without 403/429, per strategy.
  2. Which strategy reproduces Firecrawl rawHtml. Probe evidence (2026-07-16,
     Haaland page, haaland_firecrawl_rawhtml.html): Firecrawl rawHtml is a
     RENDERED DOM snapshot (Modernizr classes on <html>; FBref's JS un-comments
     tables but leaves the original <!-- --> copies in place). Expected match:
     Playwright strategy. HTTP-only (pure source) is acceptable — and cheaper —
     iff every table fbref_parse.py needs is present inside the comments.
  3. Table-id inventory per page: live ids, commented ids, duplicates
     (stats_player_summary + wages appear TWICE in the reference -> dedupe needed).
  4. Optional diff vs the Firecrawl rawHtml reference: table-id sets must match.
"""

import argparse
import asyncio
import re
import sys
import time
from pathlib import Path

from crawl4ai import AsyncWebCrawler, BrowserConfig, CrawlerRunConfig, CacheMode
from crawl4ai.async_crawler_strategy import AsyncHTTPCrawlerStrategy

# --- Swap these for the real S7b targets (match logs / NT pages) ---
PAGES = [
    "https://fbref.com/en/players/1f44ac21/Erling-Haaland",          # player page (matches probe reference)
    "https://fbref.com/en/squads/599eba19/Norway-Men-Stats",          # NT squad page (Norway — Haaland's NT, matches reference provenance)
    "https://fbref.com/en/matches/c4104726/South-Africa-Canada-June-28-2026-World-Cup",  # match page (R32, results/raw/c4104726.html — the A/B baseline)
]

SLEEP_S = 7.0        # FBref hard limit: 10 req/min. 7 s ≈ 8.5/min, safe.
OUT = Path("spike_out")

TABLE_ID_RE = re.compile(r'<table[^>]*?id="([A-Za-z0-9_]+)"')
COMMENT_RE = re.compile(r"<!--(.*?)-->", re.DOTALL)


def inventory(html: str) -> dict:
    all_ids = TABLE_ID_RE.findall(html)
    commented_ids = []
    for c in COMMENT_RE.findall(html):
        commented_ids += TABLE_ID_RE.findall(c)
    live_ids = list(all_ids)
    for cid in commented_ids:
        if cid in live_ids:
            live_ids.remove(cid)
    dupes = sorted({i for i in all_ids if all_ids.count(i) > 1})
    return {
        "total": len(all_ids),
        "live": sorted(set(live_ids)),
        "commented": sorted(set(commented_ids)),
        "dupes": dupes,
        "id_set": set(all_ids),
    }


def report(tag: str, url: str, status, html: str | None):
    print(f"\n=== {tag} :: {url}")
    if not html:
        print(f"  FAILED (status={status})")
        return None
    inv = inventory(html)
    print(f"  status={status}  bytes={len(html):,}")
    print(f"  tables: {inv['total']} total | live: {inv['live']}")
    print(f"  commented: {inv['commented']}")
    if inv["dupes"]:
        print(f"  !! duplicate ids (commented + live copies): {inv['dupes']}")
    return inv


async def run(reference: Path | None):
    OUT.mkdir(exist_ok=True)
    ref_inv = None
    if reference:
        ref_inv = report("FIRECRAWL REFERENCE", str(reference), "file", reference.read_text(encoding="utf-8"))

    results = {}

    # --- Strategy A: HTTP-only — SKIPPED (settled 2026-07-16: crawl4ai HTTP path
    #     403s on all FBref pages, same as requests/curl; and fbref_parse.py reads
    #     live-DOM only, so a pure-source fetch wouldn't help even if it returned).
    #     Commented out to avoid burning 3 more guaranteed-403 requests.
    # http_strategy = AsyncHTTPCrawlerStrategy()
    # async with AsyncWebCrawler(crawler_strategy=http_strategy) as crawler:
    #     for url in PAGES:
    #         r = await crawler.arun(url, config=CrawlerRunConfig(cache_mode=CacheMode.BYPASS))
    #         html = r.html if r.success else None
    #         inv = report("HTTP", url, r.status_code, html)
    #         if html:
    #             (OUT / f"http_{url.rstrip('/').rsplit('/', 1)[-1]}.html").write_text(html, encoding="utf-8")
    #             results[("http", url)] = inv
    #         time.sleep(SLEEP_S)

    # --- Strategy B: Playwright (fallback; rendered DOM — expect MORE tables, fewer comments) ---
    # 2026-07-16: plain Playwright hit a Cloudflare JS challenge (307/403) on all 3 pages.
    # Per the "both blocked -> retry undetected" rule, switched to browser_type="undetected"
    # (patchright stealth chromium) for exactly one more attempt.
    # Merry rerun MUST be headed (headless=False, real display) or use crawl4ai
    # managed-browser mode — headless is exactly what CF's JS challenge is killing here,
    # and it's the same public IP either way, so a headless retry buys nothing.
    async with AsyncWebCrawler(config=BrowserConfig(headless=False, browser_type="undetected")) as crawler:
        for url in PAGES:
            r = await crawler.arun(url, config=CrawlerRunConfig(cache_mode=CacheMode.BYPASS))
            html = r.html if r.success else None
            inv = report("PLAYWRIGHT", url, r.status_code, html)
            if html:
                (OUT / f"pw_{url.rstrip('/').rsplit('/', 1)[-1]}.html").write_text(html, encoding="utf-8")
                results[("pw", url)] = inv
            time.sleep(SLEEP_S)

    # --- Verdict ---
    print("\n" + "=" * 60)
    for tag in ("http", "pw"):
        ok = all((tag, u) in results for u in PAGES)
        print(f"{tag.upper()} strategy fetched all pages: {ok}")
        if ref_inv and (tag, PAGES[0]) in results:
            match = results[(tag, PAGES[0])]["id_set"] == ref_inv["id_set"]
            print(f"  {tag.upper()} table-id set == Firecrawl reference: {match}")
            if not match:
                print(f"  symmetric diff: {sorted(results[(tag, PAGES[0])]['id_set'] ^ ref_inv['id_set'])}")
    print("\nDecision: PLAYWRIGHT matching reference = drop-in Firecrawl replacement, parser unchanged.")
    print("If HTTP's commented ids cover every table fbref_parse.py extracts, prefer HTTP (lighter/faster).")
    print("Both blocked (403/429) -> retry Playwright with browser_type='undetected' before conceding.")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--reference", type=Path, default=None,
                    help="Firecrawl rawHtml sample of PAGES[0] to diff against")
    args = ap.parse_args()
    if "README-swap-me" in PAGES[2]:
        print("NOTE: PAGES[2] is a placeholder — swap in a real match URL (script will 404 it).\n")
    asyncio.run(run(args.reference))
