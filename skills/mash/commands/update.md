# MASH: update

Check for framework updates and install them.

1. Read `skills/mash/VERSION` to get the installed version. If missing, report "unknown version" and suggest re-installing.
2. Fetch the latest version from GitHub: `curl -sL https://raw.githubusercontent.com/dmarchevsky/mash/main/VERSION`.
3. Compare versions:
   - If identical, report "MASH is up to date (vX.Y.Z)" and stop.
   - If different, report the version difference.
4. Fetch the changelog section for the new version: `curl -sL https://raw.githubusercontent.com/dmarchevsky/mash/main/CHANGELOG.md` and display the relevant entries.
5. Use AskUserQuestion to ask the user whether to update.
6. If confirmed, run: `curl -sL https://raw.githubusercontent.com/dmarchevsky/mash/main/install.sh | bash`
7. Report completion.
