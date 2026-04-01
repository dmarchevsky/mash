# Changelog

All notable changes to MASH will be documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/).

## [0.4.2] — 2026-04-01

### Added
- **`/mash init <filepath>`** — accepts a project brief file as a parameter. Init-persona reads the file and uses it as a pre-seeded starting point: Phase 2 presents the content as a draft instead of asking from scratch, Phase 3 surfaces any mentioned technologies as suggested defaults, and Phase 4 scans for feature mentions and creates CREATED stubs in `.mash/plan/features/` with a suggestion to run `/mash plan <id>` for each.

## [0.4.1] — 2026-04-01

### Changed
- **init-persona sub-agent permissions** — added `webfetch: "allow"` to the required opencode permission set (was missing). Updated fallback config creation: when neither `.claude/settings.local.json` nor `opencode.json` exists, detect `.opencode/` directory and create `opencode.json` for opencode users instead of always defaulting to `.claude/settings.local.json`.

## [0.4.0] — 2026-03-31

### Added
- **Architect persona** — dual-mode architectural review agent. `pre-dev` mode checks the feature spec against `architecture.md` before implementation begins; `post-qa` mode verifies that QA evidence actually covers the stated goals and acceptance criteria (not just that tests passed). Replaces the Review persona.
- **`/mash dev <id>` reimplementation flow** — when a feature is already DONE, MASH asks whether to reimplement it. If confirmed, the architect runs pre-dev mode with a `REIMPLEMENTATION CONTEXT` block that reviews prior Dev outcomes and suggests an alternative approach before dev begins.
- **`/mash plan <description>`** — inline description passed to plan-persona as a pre-seeded starting point, skipping the opening question.
- **MASH_STATUS block reference table** in SKILL.md — documents the field schema output by each persona (`status`/`blocker`/`verified_steps` for dev, `result`/`gaps` for architect, etc.).
- **Architect output codes** added to the Status Reference section (`ARCH_APPROVED`, `ARCH_FAIL`, `ARCH_VERIFIED`).

### Changed
- **Outcome verification hardened** — dev-persona and qa-persona now require actual command output as evidence for every verification step. Prose claims ("it works") are explicitly rejected; only recorded command output counts.
- **Approach failure classification** — SKILL.md now distinguishes implementation bugs (retry with fix) from approach failures (the approach was correct but the goal wasn't achieved). Approach failures require user input before retrying and record what was tried in Technical Notes.
- **Fix/Patch flow hardened** with the same outcome classification: patch failures are now classified as implementation bugs vs. wrong fix strategy, with user input required before retrying the latter.
- **DONE marking moved to after ARCH_VERIFIED** — previously, progress.md was marked DONE immediately after QA_PASS, before the post-qa architect ran. If the architect returned ARCH_FAIL and the user chose to return to dev, progress.md would falsely show DONE. DONE is now set only when ARCH_VERIFIED.
- **Status sync table updated** — `QA_PASS` now maps to `WIP (awaiting architect)`; `ARCH_VERIFIED` maps to `DONE`.
- **Post-qa architect invocation** now lists `trigger_file` in "Read these files before starting", consistent with the pre-dev invocation.
- **Commit safety rule** updated from "Commit after QA_PASS" to "Commit after ARCH_VERIFIED".

### Fixed
- opencode compatibility: removed `subagent_type` from all `Agent()` calls (not supported in opencode).
- Premature `DONE` in progress.md when post-qa architect check failed and the feature was sent back to dev.

### Removed
- **Review persona** — replaced by the more capable Architect persona, which covers both pre-dev alignment and post-qa goal verification in a single dual-mode agent.

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
