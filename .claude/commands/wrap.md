# Wrap Up Session

Closes a working session where file changes have been applied. Runs on /wrap <prefix>.

1. Run `git status` and `git diff` — never commit blind.
2. **Refuse-on-scratch:** if any of `*.tmp`, `*.log`, `*.bak`, `test_*.*`, `*.db-journal`, `diff.txt` appear as untracked, STOP and list them. Ask: gitignore, delete, or intentional? Do not stage them.
3. Stage only the intended files by name — never `git add .`.
4. **Pipeline-landed check (WC26):** if the diff touches a loader/parser or `worldcup26_results.sql`, confirm the row count moved — run the relevant `SELECT COUNT(*)` and put the number in the commit body. A pipeline step is not "done" until the count moves, not when the file exists.
5. Commit with the message format `"$ARGUMENTS: <short description of what changed>"`. If $ARGUMENTS is empty, use "wip" as the prefix.
6. `git push` — never `--force`.
7. Confirm clean with `git status`. If not clean, say so explicitly.
8. End by **printing the drift summary** for Germán or a Cowork session to log in the brain vault's `Repos.md` — never write it there yourself (Claude Code never edits brain vault files, ever):

   ```
   Drift summary — world-cup-2026, <date>
   Commit: <hash> "<message>"
   Changed: <one line — what and why>
   Open: <anything left uncommitted/deferred, or "none — git clean">
   ```