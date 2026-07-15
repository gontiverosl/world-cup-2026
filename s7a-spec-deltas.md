# S7a Spec Deltas — resolved review items (2026-07-14)

Amendments to the S7a Paper Spec after plan-mode review. Apply on top of the
original spec in `pipeline-map.md`. All seven items resolved.

## §0 (NEW, BLOCKING GATE) — One-match proof spike via the API path

Before any other build work: Python script calls the Firecrawl API directly
(key via env var) for ONE match page → save HTML → run `fbref_parse.py` →
non-empty players + keepers CSVs. Nothing else in this spec is valid until
this passes.

Context: a 2026-07-14 Cowork spike via the Firecrawl MCP got 403
("Just a moment...") on 3 attempts against a match page — stealth and
enhanced proxies both blocked, and the engine silently ignored `waitFor`.
The MCP wrapper may differ from the direct API path, so the gate tests the
real path.

**Fallback if the API path also 403s:** manual browser-save of the remaining
~6 match pages into `results/raw/` is a legitimate ACQUIRE substitute —
tournament's nearly over, don't over-engineer around Cloudflare. PARSE
onward is unchanged either way.

## §4 REGENERATE — selection rule + scope (review item 1)

- Selection rule is NOT "played matches." It is: **any `matches` row whose
  live state differs from the seed placeholder** — score present OR
  team_home/team_away resolved. This preserves knockout bracket
  assignments (e.g. S7 QF resolutions, commit ae0b7a1) across rebuilds.
- REGENERATE is a **pure serializer**: reads live DB, writes the file,
  computes nothing. No bracket-assignment logic inside it. The two pending
  slots (third place, final) get resolved by applying the semifinal results
  to the live DB (manual UPDATE is fine — two games, no tournament logic);
  REGENERATE picks them up via the selection rule.

## §4 REGENERATE — metadata emission (review item 3)

- REGENERATE emits the `UPDATE metadata` statement as part of every full
  regen, so rebuilds never lose it.
- **`records_imported` switches to snapshot semantics**: total stat rows
  (player_stats + goalkeeper_stats) emitted in this regen — the this-run
  delta definition dies in a wholesale-regen world. `last_sync` = run
  timestamp (ISO 8601), `last_matchday` = MAX(match_date) among played.
- Note for CLAUDE.md at ship time: the metadata field-ownership table's
  `records_imported` row needs the same redefinition.

## §4 VERIFY — baseline semantics (review item 4)

- Equality assertion is **live vs scratch rebuild only** — must be exact.
- The 2026-07-13 baseline (2,263 / 149 / 104) is a **monotonic floor**
  (counts never decrease), not an equality target.
- After the final (Jul 19), the floor becomes the fixed expected final
  counts — the clean-rebuild check a public repo ships with.

## §2 Output contract — deterministic ordering (review item 5)

Every emitted statement block gets an explicit ORDER BY primary key:
`matches` by `match_id`; `player_stats` / `goalkeeper_stats` by
`(match_id, player_id)`. Byte-identical output across runs is the contract.

## §6 Failure behavior — match-level atomicity (review item 6)

Only one team's summary table found in a fetched page → **match failure**:
skip the whole match, log it. Never half-load a match.

## §4 ACQUIRE — footnote (review item 7)

The ACQUIRE script uses `requests` against `api.firecrawl.dev` only.
This does not violate the "never requests/curl/httpx" rule — that rule is
about hitting fbref.com directly. Firecrawl does the FBref fetch; the
script only talks to Firecrawl's API.
