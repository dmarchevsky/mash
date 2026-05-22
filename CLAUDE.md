# MASH Development

## Project Structure

- `install.sh` — installer script (handles both Claude Code and opencode)
- `VERSION` — single-line semver, bumped with every commit
- `skills/mash/` — Claude Code skill (SKILL.md dispatcher + commands/ + shared/ + references/)
- `opencode-skills/mash/` — opencode version of the skill
- `opencode-command/mash/` — opencode command entry point
- `.mash/plan/` — project specs and progress tracking

## After Every Change

After completing any code change, do all of the following before considering the task done:

1. **CHANGELOG.md** — Add entry under a new `## [X.Y.Z] — YYYY-MM-DD` heading (or append to today's existing heading if version matches). Use [Keep a Changelog](https://keepachangelog.com/) sections: `### Added`, `### Changed`, `### Fixed`, `### Removed`. Bold the topic, dash the detail. Skip for changes invisible to users (comment typos, whitespace).

2. **README.md** — Review whether the change affects anything documented: commands, installation, architecture, project structure, or design principles. Update only affected sections. Skip if nothing user-facing changed.

3. **VERSION** — Bump the single-line semver:
   - **patch** (Z+1): bug fixes, internal improvements
   - **minor** (Y+1, Z=0): new features, new commands, behavioral changes
   - **major** (X+1, Y=0, Z=0): breaking changes (only when explicitly requested)

4. **Commit & push** — Stage all changed files. Commit message format:
   ```
   <type>: <description>; bump X.Y.Z
   ```
   Types: `feat`, `fix`, `refactor`, `chore`, `docs`. Then `git push`.
