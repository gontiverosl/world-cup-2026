# Wrap Up Session

This is a prompt to close a working session where changes to files have been applied. This runs whenever /wrap <prefix> is called.

1. Run git diff and git status bash commands, never commit blind.
2. Stage specific files — never git add . Stage the files shown as modified or untracked in git status, excluding scratch files (*.log, *.bak, test_*.*, diff.txt, and any others in .gitignore).
3. Commit with the message format "$ARGUMENTS: <short description of what changed>". If $ARGUMENTS is empty, use "wip" as the prefix.
4. git push — never --force
5. Confirm clean with git status