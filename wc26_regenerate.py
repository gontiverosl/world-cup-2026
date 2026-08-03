"""
wc26_regenerate.py — REGENERATE node: live DB → worldcup26_results.sql, wholesale.

Replaces generate_inserts.py, which appended blindly (re-running duplicated the
block). This regenerates the whole file from scratch every run: idempotent, and
byte-identical across runs given unchanged live state.

worldcup26_results.sql is a DERIVED ARTIFACT from here on — never hand-edited.

This script is a PURE SERIALIZER: it reads the live DB, writes the file, and
computes nothing. No bracket logic, no metadata computation. Whoever changes the
data (wc26_update.py) owns writing it to the live DB first; this only serializes.

Usage:
    python3 wc26_regenerate.py [--out PATH]
"""

import os
import sys
import logging
import sqlite3
import pandas as pd

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "worldcup26.db")
RESULTS_SQL = os.path.join(BASE_DIR, "worldcup26_results.sql")
LOG_PATH = os.path.join(BASE_DIR, "worldcup26.log")

logging.basicConfig(
    filename=LOG_PATH,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
)

# stat_id excluded — AUTOINCREMENT, the DB assigns it on rebuild
PLAYER_COLS = [
    "player_id",
    "match_id",
    "minutes_played",
    "goals",
    "assists",
    "pk_made",
    "pk_att",
    "shots",
    "shots_on_goal",
    "yellow_cards",
    "red_cards",
    "fouls",
    "fouls_drawn",
    "offsides",
    "crosses",
    "tackles_won",
    "interceptions",
    "own_goals",
    "pk_won",
    "pk_conceded",
]

KEEPER_COLS = [
    "player_id",
    "match_id",
    "minutes_played",
    "shots_on_target_against",
    "goals_against",
    "saves",
]

# Dynamic match columns, fixed order. team_home/team_away are emitted for knockout
# rows ONLY — group-stage teams are seed-owned and must not be restated here.
MATCH_TEXT_COLS = ("team_home", "team_away", "referee")
MATCH_DYNAMIC_COLS = [
    "team_home",
    "team_away",
    "goals_home",
    "goals_away",
    "pk_home",
    "pk_away",
    "corners_home",
    "corners_away",
    "possession_home",
    "possession_away",
    "attendance",
    "referee",
]

# Selection rule: NOT "played". A results file that only carried played matches
# would silently drop resolved-but-unplayed knockout brackets (e.g. match_id=101,
# FRA v ESP) — they would rebuild as NULL teams with no error. The rule is "any row
# whose live state differs from the seed placeholder": score present OR teams resolved.
MATCH_QUERY = """
    SELECT * FROM matches
    WHERE goals_home IS NOT NULL
       OR (group_name = 'knock-out' AND team_home IS NOT NULL)
    ORDER BY match_id
"""


def sql_literal(value, is_text):
    """Python scalar → SQL literal. Text is single-quote escaped; None → NULL."""
    if value is None or (not is_text and pd.isna(value)):
        return "NULL"
    if is_text:
        escaped = str(value).replace("'", "''")
        return f"'{escaped}'"
    if isinstance(value, float):
        return str(value)
    return str(int(value))


def load_state(db_path):
    """Read every dynamic row from the live DB. Deterministic ORDER BY on each query."""
    conn = None
    try:
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        matches = [dict(r) for r in conn.execute(MATCH_QUERY)]
        metadata = dict(conn.execute("SELECT * FROM metadata").fetchone())
        player_df = pd.read_sql(
            "SELECT * FROM player_stats ORDER BY match_id, player_id", conn
        )
        keeper_df = pd.read_sql(
            "SELECT * FROM goalkeeper_stats ORDER BY match_id, player_id", conn
        )
        return matches, metadata, player_df, keeper_df
    finally:
        if conn:
            conn.close()


def drop_orphans(df, table):
    """NULL player_id = fbref_id never resolved to a squad member. Warn and drop —
    never emit a row that would rebuild as an orphan."""
    n_null = df["player_id"].isna().sum()
    if n_null:
        logging.warning(
            f"regenerate: {n_null} {table} rows with NULL player_id — skipped."
        )
        df = df[df["player_id"].notna()].copy()
    return df


def match_updates(matches):
    """One single-line UPDATE per selected match, non-NULL dynamic columns only.
    Emitting NULLs would overwrite seed values with NULL on rebuild."""
    lines = []
    for row in matches:
        is_knockout = row["group_name"] == "knock-out"
        assignments = []
        for col in MATCH_DYNAMIC_COLS:
            if col in ("team_home", "team_away") and not is_knockout:
                continue
            value = row[col]
            if value is None:
                continue
            assignments.append(f"{col}={sql_literal(value, col in MATCH_TEXT_COLS)}")
        if not assignments:
            continue
        lines.append(
            f"UPDATE matches SET {', '.join(assignments)} WHERE match_id={row['match_id']};"
        )
    return lines


def stat_inserts(df, table, cols):
    """INSERT OR IGNORE per row — idempotent against the UNIQUE (player_id, match_id)."""
    col_list = ", ".join(cols)
    lines = []
    for _, row in df.iterrows():
        vals = ", ".join(sql_literal(row[c], False) for c in cols)
        lines.append(f"INSERT OR IGNORE INTO {table} ({col_list}) VALUES ({vals});")
    return lines


def metadata_update(metadata):
    """Only the three task-owned fields. schema_version/api_version are seed-authored —
    restating them here would let a results file silently override a schema bump."""
    fields = ", ".join(
        f"{col}={sql_literal(metadata[col], True)}"
        for col in ("last_sync", "last_matchday")
    )
    imported = sql_literal(metadata["records_imported"], False)
    return f"UPDATE metadata SET {fields}, records_imported={imported};"


def serialize(matches, metadata, player_df, keeper_df):
    """Build the complete file body. Pure function of its inputs — no clock, no I/O."""
    blocks = [
        "-- ============================================================",
        "-- worldcup26_results.sql — GENERATED ARTIFACT, DO NOT HAND-EDIT",
        "--",
        "-- Regenerated wholesale from the live DB by wc26_regenerate.py.",
        "-- Any manual edit here is lost on the next run. To change data:",
        "-- change the live DB, then regenerate.",
        "--",
        "-- Rebuild: sqlite3 worldcup26.db < worldcup26_seed.sql \\",
        "--            && sqlite3 worldcup26.db < worldcup26_results.sql",
        "-- ============================================================",
        "",
        "-- matches — scores + knockout bracket assignments (ORDER BY match_id)",
    ]
    blocks.extend(match_updates(matches))
    blocks.extend(["", "-- player_stats (ORDER BY match_id, player_id)"])
    blocks.extend(stat_inserts(player_df, "player_stats", PLAYER_COLS))
    blocks.extend(["", "-- goalkeeper_stats (ORDER BY match_id, player_id)"])
    blocks.extend(stat_inserts(keeper_df, "goalkeeper_stats", KEEPER_COLS))
    blocks.extend(["", "-- metadata singleton"])
    blocks.append(metadata_update(metadata))
    blocks.append("")
    return "\n".join(blocks)


def main():
    out_path = RESULTS_SQL
    if "--out" in sys.argv:
        out_path = sys.argv[sys.argv.index("--out") + 1]

    matches, metadata, player_df, keeper_df = load_state(DB_PATH)
    player_df = drop_orphans(player_df, "player_stats")
    keeper_df = drop_orphans(keeper_df, "goalkeeper_stats")

    body = serialize(matches, metadata, player_df, keeper_df)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(body)

    logging.info(
        f"regenerate: {len(matches)} match UPDATEs, {len(player_df)} player_stats, "
        f"{len(keeper_df)} goalkeeper_stats → {out_path}"
    )
    print(
        f"Regenerated {out_path} — {len(matches)} match UPDATEs, "
        f"{len(player_df)} player_stats, {len(keeper_df)} goalkeeper_stats."
    )


if __name__ == "__main__":
    main()
