# Changelog

All notable changes to MASH will be documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/).

## [0.3.0] — 2026-03-27

### Added
- **opencode support** — MASH now works with opencode in addition to Claude Code. Includes skill registration, command registration, and `opencode.json` config with permissions.
- **Fix/Patch/Review personas** — three new personas for defect handling: Fix (collaborative debugging), Patch (minimal-change implementation), Review (test maintenance after dev/QA cycles). New commands: `/mash fix`, `/mash fix <id>`, `/mash fix <description>`.
- **`/mash config` command** — view and change git settings and sub-agent permissions after initialization.
- **Windows support** — installation via Git Bash on Windows.
- **No-git project support** — `git: none` setting allows MASH to manage projects without git.
- **Command dispatch table** in SKILL.md mapping each command to its execution flow.

### Changed
- init-persona handles both clients — sub-agent permissions setup detects and writes to both `.claude/settings.local.json` and `opencode.json`.
- dev-persona and qa-persona reference `architecture.md` for source and test directories instead of hardcoding `src/` and `tests/`.
- PATCH LOOP restructured — QA_PASS case broken into clear sub-steps; step numbering fixed.
- README updated — project structure diagram corrected, all seven personas documented, commands table includes fix and config.
- Templates use plain bullets instead of `- [ ]` checkboxes.
- Installer drops PowerShell — Windows installation via Git Bash only.
- Installer gitignores `.claude/settings.local.json` (machine-specific permissions).
- INVOKE REVIEW passes trigger context (the specific feature/defect file that triggered it).
- CONFIG correctly references opencode.json `permission` schema.

### Fixed
- PATCH LOOP step numbering mismatch (dispatch referenced step 8, heading said 7)
- Dashboard recommendation logic
- Install script interactive prompt (tty check, bash process substitution)
- Empty `## Commands` header in SKILL.md
- opencode-commands missing `name` field in frontmatter

## [0.1.1] — 2026-03-26

### Fixed
- macOS compatibility: use explicit `tar -xz` flags for BSD tar
- macOS compatibility: replace `ls -A` empty dir check with portable `find`
- Remove useless `cat` in version reads (`tr < file` instead of `cat file | tr`)

## [0.1.0] — 2026-03-24

### Added
- Init persona with multi-turn interactive project definition
- Plan persona with iterative feature brainstorming and specification
- Dev persona for autonomous feature implementation via sub-agents
- QA persona for test-driven verification of acceptance criteria
- Git workflow settings: worktree branching or current branch, auto or manual commit
- Permission checking and auto-configuration for sub-agent autonomy
- Install script with per-project installation via `curl | bash`
- Version tracking and `mash update` command
