# Full 48-Team Roster Reconciliation Report

**Date:** 2026-07-08
**Scope:** Every one of the 1,248 current `players` rows across all 48 teams, cross-checked against each team's official FIFA World Cup 2026 squad page (`fifa.com`).

## Method

1. Fetched all 48 official FIFA squad pages (`fifa.com/.../teams/<slug>/squad`), reusing the slugs/hexes established during the `fbref_team_id` crosswalk work.
2. Parsed each into a 26-name roster (name-dedup on FIFA's markdown, which repeats each name/position string twice).
3. Matched every current DB row against its team's parsed FIFA roster using a normalized matcher:
   - Tier 1: exact squashed-name match (accents stripped, including non-NFKD letters like ø/ı/ğ/ş/ß, both native and German-style ue/oe/ae transliteration variants tried)
   - Tier 2: mononym/substring containment (e.g. "Neymar" vs "NEYMAR JR")
   - Tier 3: last-name exact + first-name fuzzy (small edit distance + shared prefix) — this is the tier that correctly **rejects** last-name-only coincidences (the Jurriën Timber / Quinten Timber and Alexandre Pierre / Leverton Pierre cases from the earlier 20-team check)
   - Tier 4: order-invariant whole-name fuzzy match (sorted-character edit distance) — catches name-order flips (surname-first conventions) and transliteration drift in either name part, not just the first name
4. Anything still unmatched after all four tiers was checked by hand against general football-knowledge (documented nicknames, name-order conventions). That resolution is **not from the FIFA/FBref data itself** — flagged as its own category below, never silently folded into "clean."

## Category rule (exhaustive, non-overlapping — every team in exactly one)

- **Clean**: zero unmatched rows from the algorithm. Nothing needed hand resolution.
- **Nickname-resolved**: the algorithm produced unmatched rows, but *every one* of them resolved against a well-documented nickname/name-order pattern.
- **Genuine-unmatched**: at least one row remains unresolved after both the algorithm and hand-checking. A team with 4 nickname-resolved rows and 1 real finding goes here, not in nickname-resolved — the presence of one unresolved row is what decides the bucket, not the majority.

## All 48 teams

| Team | Category | Details |
|---|---|---|
| ALG | Clean | — |
| ARG | Nickname-resolved | Flaco López≈Jose Manuel Lopez; Nicolás González≈Nico Gonzalez; Nicolás Paz≈Nico Paz |
| AUS | Nickname-resolved | Cammy Devlin≈Cameron Devlin; Mo Touré≈Mohamed Toure |
| AUT | Clean | — |
| BEL | Clean | — |
| BIH | Clean | — |
| BRA | Clean | — |
| CAN | Clean | — |
| CIV | Nickname-resolved | Obite N'Dicka≈Evan Ndicka (FIFA displays a different given name from the same full name) |
| COD | Clean | — |
| COL | Clean | — |
| CPV | Nickname-resolved | Pico≈Pico Lopes (mononym) |
| CRO | Clean | — |
| CUW | Clean | — |
| CZE | Clean | — |
| ECU | Clean | — |
| EGY | **Genuine-unmatched** | Mohanad Mostafa — **high confidence real finding**, confirmed absent from FBref as well as FIFA (from the earlier league-backfill pass) |
| ENG | Clean | — |
| ESP | Clean | — |
| FRA | Clean | — |
| GER | Clean | — |
| GHA | Nickname-resolved | Abdul Rahman Baba≈Baba Rahman (surname-first vs. surname-last ordering) |
| HAI | **Genuine-unmatched** | Duke Lacroix — low confidence. Only surname match on FIFA's list is "Markhus LACROIX" — different first name, no plausible nickname link found |
| IRN | **Genuine-unmatched** | Dennis Eckert — low confidence, surname doesn't match "Dennis DARGAHI" at all. Hossein Kanaanizadegan — medium confidence, plausibly "Hossein KANANI" (edit distance 8/22, large gap) |
| IRQ | **Genuine-unmatched** | Manaf Younis — medium confidence, plausibly "MUNAF YOUNUS" (edit distance 4/11, vowel-transliteration pattern) |
| JOR | **Genuine-unmatched** | Mo Abualnadi resolves via nickname, but 4 rows don't: Mohammad Taha (low — confirmed not a duplicate of the also-present "Mohannad Abu Taha," different `fbref_id`/club, no FIFA match either way); Nour Bani Attiah (medium — plausibly "NOUR BANIATEYAH," edit distance 4/15); Odeh Al-Fakhouri (low — shares a surname with the already-matched real GK "Abdallah Al-Fakhouri," could be a relative or could be contamination); Sharara (low — mononym, no candidate at all) |
| JPN | Clean | — |
| KOR | Clean | — |
| KSA | **Genuine-unmatched** | Firas Al-Buraikan — medium confidence, plausibly "FERAS ALBRIKAN" (edit distance 4/14) |
| MAR | Clean | — |
| MEX | Clean | — |
| NED | Clean | — |
| NOR | Clean | — |
| NZL | Clean | — |
| PAN | Clean | — |
| PAR | Nickname-resolved | Kaku≈Alejandro Romero Gamarra (well-documented nickname) |
| POR | Clean | — |
| QAT | **Genuine-unmatched** | Ró-Ró — low confidence, no plausible match found. Tahsin Jamshid — low confidence, first name matches "TAHSIN MOHAMMED" but surname doesn't |
| RSA | Clean | — |
| SCO | Clean | — |
| SEN | Clean | — |
| SUI | Clean | — |
| SWE | Clean | — |
| TUN | Clean | — |
| TUR | Clean | — |
| URU | Clean | — |
| USA | Nickname-resolved | Alejandro Zendejas≈Alex Zendejas; Gio Reyna≈Giovanni Reyna |
| UZB | Nickname-resolved | Aziz Ganiev≈Azizjon Ganiev; Bekhruz Karimov≈Behruzjon Karimov |

## Category totals (33 + 8 + 7 = 48)

- **Clean: 33** — ALG, AUT, BEL, BIH, BRA, CAN, COD, COL, CRO, CUW, CZE, ECU, ENG, ESP, FRA, GER, JPN, KOR, MAR, MEX, NED, NOR, NZL, PAN, POR, RSA, SCO, SEN, SUI, SWE, TUN, TUR, URU
- **Nickname-resolved: 8** — ARG, AUS, CIV, CPV, GHA, PAR, USA, UZB
- **Genuine-unmatched: 7** — EGY, HAI, IRN, IRQ, JOR, KSA, QAT

## Bottom line

Across the 7 genuine-unmatched teams, 12 individual rows remain flagged:

- **1 high confidence** real finding: Mohanad Mostafa (EGY)
- **4 medium confidence** likely-transliteration cases: Hossein Kanaanizadegan (IRN), Manaf Younis (IRQ), Nour Bani Attiah (JOR), Firas Al-Buraikan (KSA)
- **7 low confidence** rows needing manual review: Duke Lacroix (HAI), Dennis Eckert (IRN), Mohammad Taha (JOR), Odeh Al-Fakhouri (JOR), Sharara (JOR), Ró-Ró (QAT), Tahsin Jamshid (QAT)

**Revision note:** the first draft of this file miscategorized HAI (listed as both nickname-resolved and genuine-unmatched), silently dropped ALG and PAN from any bucket, and lost the "Nour Bani Attiah" row from JOR's table entirely. This version derives every row directly from the script's raw per-team output instead of hand-summarizing from memory — the table above is authoritative.

No database changes were made by this reconciliation pass.
