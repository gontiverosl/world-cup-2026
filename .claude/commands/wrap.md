# Wrap Up Session

Closes a working session where file changes have been applied. Runs on /wrap <prefix>.

1. `git fetch --prune` — bring remote-tracking refs and branch deletions up to date before anything else.
2. Run `git status` and `git diff` — never commit blind.
3. **Refuse-on-scratch:** if any of `*.tmp`, `*.log`, `*.bak`, `test_*.*`, `*.db-journal`, `diff.txt` appear as untracked, STOP and list them. Ask: gitignore, delete, or intentional? Do not stage them.
4. Stage only the intended files by name — never `git add .`.
5. **Pipeline-landed check (WC26):** if the diff touches a loader/parser or `worldcup26_results.sql`, confirm the row count moved — run the relevant `SELECT COUNT(*)` and put the number in the commit body. A pipeline step is not "done" until the count moves, not when the file exists.
6. Commit with the message format `"$ARGUMENTS: <short description of what changed>"`. If $ARGUMENTS is empty, use "wip" as the prefix.
7. `git push` — never `--force`.
8. Confirm clean with `git status`. If not clean, say so explicitly.
9. End by **printing the drift summary plus `git branch -vv`** — for Germán or a Cowork session to log in the brain vault's `Repos.md`; never write it there yourself (Claude Code never edits brain vault files, ever). The branch print exists because /wrap is commit-scoped and can't otherwise catch graph-scoped drift (unmerged branches, a local main behind origin) — that's how wc26 ran clean wraps through S7–S8 while three branches piled up unnoticed:

   ```
   Drift summary — world-cup-2026, <date>
   Commit: <hash> "<message>"
   Changed: <one line — what and why>
   Open: <anything left uncommitted/deferred, or "none — git clean">

   <output of `git branch -vv`>
   ```
