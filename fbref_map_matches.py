import os
import sqlite3
import logging

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "worldcup26.db")
LOG_PATH = os.path.join(BASE_DIR, "worldcup26.log")

logging.basicConfig(
    filename=LOG_PATH, level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

# FBref slug fragment → FIFA code (non-obvious mappings only)
SLUG_TO_CODE = {
    "Korea-Republic":          "KOR",
    "Bosnia-and-Herzegovina":  "BIH",
    "Turkiye":                 "TUR",
    "Curacao":                 "CUW",
    "Cote-dIvoire":            "CIV",
    "IR-Iran":                 "IRN",
    "Congo-DR":                "COD",
    "South-Africa":            "RSA",
    "United-States":           "USA",
    "Saudi-Arabia":            "KSA",
    "New-Zealand":             "NZL",
    "Cabo-Verde":              "CPV",
    "Korea-Republic":          "KOR",
}

# All 73 played matches scraped from FBref schedule page (2026-06-29)
# (hex, date, team1_slug, team2_slug)
# R32 match flagged — team_home/away NULL in DB until bracket is filled
MATCHES = [
    # --- Round of 32 (1 match played) ---
    ("c4104726", "2026-06-28", "South-Africa",            "Canada"),            # R32
    # --- Group stage (72 matches) ---
    ("3c1e3816", "2026-06-11", "Mexico",                  "South-Africa"),
    ("beebb792", "2026-06-11", "Korea-Republic",          "Czechia"),
    ("f6d2bd84", "2026-06-12", "Canada",                  "Bosnia-and-Herzegovina"),
    ("f6c0596c", "2026-06-12", "United-States",           "Paraguay"),
    ("58580af9", "2026-06-13", "Qatar",                   "Switzerland"),
    ("72d993fd", "2026-06-13", "Brazil",                  "Morocco"),
    ("4ff2342a", "2026-06-13", "Australia",               "Turkiye"),
    ("58c3106f", "2026-06-13", "Haiti",                   "Scotland"),
    ("a2c54ed9", "2026-06-14", "Germany",                 "Curacao"),
    ("faa0cb98", "2026-06-14", "Netherlands",             "Japan"),
    ("f8ee7eef", "2026-06-14", "Cote-dIvoire",            "Ecuador"),
    ("6df52cfd", "2026-06-14", "Sweden",                  "Tunisia"),
    ("5f18a385", "2026-06-15", "Belgium",                 "Egypt"),
    ("c100284d", "2026-06-15", "Spain",                   "Cabo-Verde"),
    ("82de5964", "2026-06-15", "Saudi-Arabia",            "Uruguay"),
    ("a039dc32", "2026-06-15", "IR-Iran",                 "New-Zealand"),
    ("2712fac7", "2026-06-16", "France",                  "Senegal"),
    ("17eda16a", "2026-06-16", "Iraq",                    "Norway"),
    ("881ab666", "2026-06-16", "Argentina",               "Algeria"),
    ("140e19d9", "2026-06-16", "Austria",                 "Jordan"),
    ("c95830e9", "2026-06-17", "Portugal",                "Congo-DR"),
    ("c42ce3be", "2026-06-17", "England",                 "Croatia"),
    ("9f71086a", "2026-06-17", "Ghana",                   "Panama"),
    ("3329959e", "2026-06-17", "Uzbekistan",              "Colombia"),
    ("5134daab", "2026-06-18", "Switzerland",             "Bosnia-and-Herzegovina"),
    ("02f675d6", "2026-06-18", "Czechia",                 "South-Africa"),
    ("60dedabb", "2026-06-18", "Canada",                  "Qatar"),
    ("50a429da", "2026-06-18", "Mexico",                  "Korea-Republic"),
    ("580cb771", "2026-06-19", "United-States",           "Australia"),
    ("2a469714", "2026-06-19", "Scotland",                "Morocco"),
    ("82209c60", "2026-06-19", "Turkiye",                 "Paraguay"),
    ("48cce92a", "2026-06-19", "Brazil",                  "Haiti"),
    ("816f4180", "2026-06-20", "Netherlands",             "Sweden"),
    ("43fec9f3", "2026-06-20", "Germany",                 "Cote-dIvoire"),
    ("ca7eecdb", "2026-06-20", "Ecuador",                 "Curacao"),
    ("27695f4a", "2026-06-20", "Tunisia",                 "Japan"),
    ("c96f559b", "2026-06-21", "Belgium",                 "IR-Iran"),
    ("0fcac1d8", "2026-06-21", "Spain",                   "Saudi-Arabia"),
    ("bc0e570b", "2026-06-21", "Uruguay",                 "Cabo-Verde"),
    ("d5699a16", "2026-06-21", "New-Zealand",             "Egypt"),
    ("e7d8a062", "2026-06-22", "Argentina",               "Austria"),
    ("31f1f241", "2026-06-22", "France",                  "Iraq"),
    ("7382111b", "2026-06-22", "Norway",                  "Senegal"),
    ("eb19002c", "2026-06-22", "Jordan",                  "Algeria"),
    ("904bbbdc", "2026-06-23", "Portugal",                "Uzbekistan"),
    ("3dac8725", "2026-06-23", "England",                 "Ghana"),
    ("28a6d770", "2026-06-23", "Panama",                  "Croatia"),
    ("f2e8741b", "2026-06-23", "Colombia",                "Congo-DR"),
    ("a59cb59d", "2026-06-24", "Bosnia-and-Herzegovina",  "Qatar"),
    ("199a57aa", "2026-06-24", "Switzerland",             "Canada"),
    ("2307866a", "2026-06-24", "Morocco",                 "Haiti"),
    ("0ef71ab6", "2026-06-24", "Scotland",                "Brazil"),
    ("f26b468c", "2026-06-24", "Czechia",                 "Mexico"),
    ("311661a5", "2026-06-24", "South-Africa",            "Korea-Republic"),
    ("cc4ebc5b", "2026-06-25", "Ecuador",                 "Germany"),
    ("89835aff", "2026-06-25", "Curacao",                 "Cote-dIvoire"),
    ("994aa701", "2026-06-25", "Japan",                   "Sweden"),
    ("63b14e23", "2026-06-25", "Tunisia",                 "Netherlands"),
    ("c8fa19f5", "2026-06-25", "Paraguay",                "Australia"),
    ("358fd0fc", "2026-06-25", "Turkiye",                 "United-States"),
    ("1bcdcfc8", "2026-06-26", "Norway",                  "France"),
    ("583c1910", "2026-06-26", "Senegal",                 "Iraq"),
    ("48dd64d5", "2026-06-26", "Uruguay",                 "Spain"),
    ("8d6d70b6", "2026-06-26", "Cabo-Verde",              "Saudi-Arabia"),
    ("acc93b55", "2026-06-26", "Egypt",                   "IR-Iran"),
    ("f527457d", "2026-06-26", "New-Zealand",             "Belgium"),
    ("d7e30dec", "2026-06-27", "Panama",                  "England"),
    ("a051b2ea", "2026-06-27", "Croatia",                 "Ghana"),
    ("6287f9c7", "2026-06-27", "Congo-DR",                "Uzbekistan"),
    ("ded93e98", "2026-06-27", "Colombia",                "Portugal"),
    ("5ec98037", "2026-06-27", "Jordan",                  "Argentina"),
    ("79a8f8c8", "2026-06-27", "Algeria",                 "Austria"),
]

def slug_to_code(slug):
    """Convert FBref URL slug fragment to FIFA team code."""
    if slug in SLUG_TO_CODE:
        return SLUG_TO_CODE[slug]
    # Single-word team names match directly (Germany, France, etc.)
    # Build a fallback from DB at runtime — see main()
    return None

def main():
    conn = None
    try:
        conn = sqlite3.connect(DB_PATH)
        cur = conn.cursor()

        # Build runtime lookup: team_id → for single-word slugs matching team_id directly
        # (e.g. "Germany" slug matches team_id "GER" via teams.team_id? No — match via country)
        # We rely on SLUG_TO_CODE for all non-trivial cases; single-word slugs ARE the team_id
        # for most teams (Germany=GER, France=FRA ...) — actually no, we use country name lookup.
        # Simpler: for slugs not in SLUG_TO_CODE, try matching against teams.country (space-normalized)
        cur.execute("SELECT team_id, country FROM teams")
        country_map = {row[1].lower(): row[0] for row in cur.fetchall()}

        def resolve(slug):
            if slug in SLUG_TO_CODE:
                return SLUG_TO_CODE[slug]
            # Try direct country name match (replace hyphen with space)
            name = slug.replace("-", " ").lower()
            return country_map.get(name)

        updated = 0
        skipped = 0

        for hex_id, date, t1_slug, t2_slug in MATCHES:
            c1 = resolve(t1_slug)
            c2 = resolve(t2_slug)

            if not c1 or not c2:
                logging.warning(f"Could not resolve slugs: {t1_slug}={c1}, {t2_slug}={c2} — skipped {hex_id}")
                skipped += 1
                continue

            # Match on date + either team ordering (home/away may vary)
            cur.execute("""
                SELECT match_id FROM matches
                WHERE match_date = ?
                  AND ((team_home = ? AND team_away = ?)
                    OR (team_home = ? AND team_away = ?))
            """, (date, c1, c2, c2, c1))
            row = cur.fetchone()

            if row is None:
                logging.warning(f"No DB match for {hex_id} ({c1} vs {c2} on {date}) — team_home/away may be NULL (R32?)")
                skipped += 1
                continue

            match_id = row[0]
            cur.execute("UPDATE matches SET fbref_match_id = ? WHERE match_id = ?", (hex_id, match_id))
            updated += 1

        conn.commit()
        logging.info(f"fbref_map_matches: {updated} fbref_match_id values set, {skipped} skipped.")
        print(f"Done — {updated} updated, {skipped} skipped.")

    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    main()
