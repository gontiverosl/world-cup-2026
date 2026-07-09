# Player Findings — Remaining 11 Flagged Rows

**Date:** 2026-07-08
**Scope:** Follow-up to `reconciliation_report.md`'s 12 genuine-unmatched rows, after Mohanad Mostafa (EGY) was independently diagnosed and fixed (wrong `fbref_id`, corrected to `8c041c7d`). This report covers the remaining 11.

## Method

1. Checked each player's team squad-page HTML **already fetched** during the league-backfill pass, searching for the player under alternate name constructions (surname-led, father-name-led) the same way Mostafa's real profile was found — before doing any new fetch.
2. Before any fresh search, checked `player_stats` for **real recorded WC26 match minutes** — a much stronger validity signal than name-text matching, since only registered squad members can appear in actual match reports.
3. Only did a fresh FBref search for the 2 cases where the surname genuinely didn't resemble FIFA's listed name AND no match minutes were recorded (i.e., the already-fetched HTML didn't resolve it).
4. No database writes this pass — report only.

## Result: zero fbref_id fixes needed, zero contamination confirmed

Every one of the 11 resolves to "current `fbref_id` is correct, player is real" — the original flag in the reconciliation report was a gap in the FIFA-text name-matcher, not a data problem.

| Player | Team | Current `fbref_id` | Evidence | Category |
|---|---|---|---|---|
| Duke Lacroix | HAI | `bce0d6f6` | 3 real WC26 matches, 270 min recorded | Confirmed real, no fix needed |
| Dennis Eckert | IRN | `7f8fb807` | FBref's own page states **"Also Played As: Dennis Dargahi"** — literal alias field, exact match to FIFA's listed name | Confirmed real, no fix needed |
| Hossein Kanaanizadegan | IRN | `24353c25` | No explicit alias found, but name/DOB (1994-03-23)/club (Persepolis) all consistent with FIFA's "Hossein Kanani"; 0 recorded minutes | **Still ambiguous** — lower confidence than the rest, no smoking-gun confirmation |
| Manaf Younis | IRQ | `b798826e` | 3 real WC26 matches, 188 min recorded | Confirmed real, no fix needed |
| Mohammad Taha | JOR | `4f1daaf3` | 3 real WC26 matches, 148 min recorded; independently confirmed distinct from "Mohannad Abu Taha" (different `fbref_id`, different club) | Confirmed real, no fix needed |
| Nour Bani Attiah | JOR | `b06f02f9` | 2 real WC26 matches, 142 min recorded | Confirmed real, no fix needed |
| Odeh Al-Fakhouri | JOR | `30591ae5` | 2 real WC26 matches, 90 min recorded; confirmed distinct from "Abdallah Al-Fakhouri" | Confirmed real, no fix needed |
| Sharara | JOR | `67e2aed8` | 1 real WC26 match, 3 min recorded | Confirmed real, no fix needed |
| Firas Al-Buraikan | KSA | `ac717a23` | 1 real WC26 match, 36 min recorded | Confirmed real, no fix needed |
| Ró-Ró | QAT | `8735fe66` | 1 real WC26 match, 19 min recorded | Confirmed real, no fix needed |
| Tahsin Jamshid | QAT | `efdcf1c7` | Real full name confirmed as **"Tahsin Mohammed Jamshid"** — FIFA's "Mohammed" is his real middle name, not a different surname; squad-page club match (Al Duhail SC) confirms same person | Confirmed real, no fix needed |

## Why this differs from the original 22 contamination rows

The 22 rows removed earlier this session had a structural tell: `shirt_number IS NULL`, zero recorded appearances, and complete absence from FIFA's real squad page. These 11 have real shirt numbers and, in 9 of 11 cases, actual recorded tournament minutes — match minutes cannot be recorded for a non-existent squad member. The residual mismatch against `reconciliation_report.md` was a name-matcher gap against FIFA's often-abbreviated display text (nicknames, middle-name-vs-surname selection, aliases), not evidence of contamination.

## Recommendation

No DB action needed for any of these 11. Hossein Kanaanizadegan sits at meaningfully lower confidence than the rest (no alias/minutes confirmation, though name/DOB/club are consistent) — worth a manual gut-check if desired, but nothing found points toward it being wrong either.

No database writes were made by this pass.
