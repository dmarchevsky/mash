# Changelog

All notable changes to MASH will be documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/).

## [0.6.7] — 2026-04-03

### Fixed
- **opencode `@mash fix <desc>` command parsing** — SKILL.md now explicitly states that bare commands (without the `mash` prefix) are valid when invoked via `@mash`. Prevents the model from failing to match `fix some bug` against the `mash fix <desc>` dispatch pattern.

## [0.6.6] — 2026-04-03

### Fixed
- **opencode agent `ProviderModelNotFoundError`** — removed `model: inherit` from agent frontmatter; `inherit` did not resolve when opencode spawned sub-agents from within the MASH agent context, causing the fix/dev flows to fail immediately.

## [0.6.5] — 2026-04-03

### Fixed
- **opencode agent `@` autocomplete** — changed agent `mode` from `primary` to `all` so `@mash` appears in the autocomplete menu alongside built-in agents.

## [0.6.4] — 2026-04-03

### Fixed
- **opencode `@mash` collision** — references and VERSION moved from `~/.config/opencode/agents/mash/` to `~/.config/opencode/mash/`. Having a directory named `mash/` alongside `agents/mash.md` caused opencode to resolve `@mash` to the directory file list instead of the agent.

## [0.6.3] — 2026-04-03

### Changed
- **opencode: skill → agent** — MASH is now installed as a native opencode agent (`~/.config/opencode/agents/mash.md`) instead of a skill. Invocation is explicit via `@mash` or automatically as the default agent. Eliminates unreliable keyword-matching that caused `mash fix` to be misrouted.
- **`default_agent: mash`** — `opencode.json` template now sets MASH as the default agent. Init persona adds this to `opencode.json` during `mash init` for existing projects.
- **install.sh** — migrates legacy `~/.config/opencode/skills/mash/` to `~/.config/opencode/agents/mash/` on update.

## [0.6.2] — 2026-04-03

### Fixed
- **opencode skill description** — added `fix` and `update` to the command list in the opencode skill frontmatter description, so opencode correctly routes `mash fix <desc>` to the mash skill.

## [0.6.1] — 2026-04-03

### Added
- **`mash plan <id>`** — redefine an existing feature spec interactively, then reimplement it immediately. Runs plan-persona in refinement mode (multi-turn conversation, updates the feature file in place), syncs the dev file preserving prior outcome sections, then proceeds directly to the implementation loop with the reimplementation context block. Mirrors the `fix → patch` flow.

### Changed
- **Architect ARCH_VERIFIED rule tightened** — if every acceptance criterion has only TECHNICAL_ONLY evidence (no functional verification of the user's goal exists), the result is now `ARCH_FAIL` with `GOAL_NOT_VERIFIED` rather than a passing `ARCH_VERIFIED`.
- **TECHNICAL_ONLY items excluded from gap count** — `gaps` in the MASH_STATUS block no longer counts TECHNICAL_ONLY items; they are noted but do not produce ARCH_FAIL on their own (except the all-TECHNICAL_ONLY case above).
- **Init recovery branching** — when `.mash/plan/` files already have content, init-persona now determines precisely where to resume: project.md done → resume at architecture; both done → resume at scaffolding; all done → present a section-select menu instead of re-running the full flow.
- **Patch persona Common Mistakes section** — documents the five most frequent patch errors: expanding fix scope, substituting the real target, declaring PATCH_DONE before all criteria are checked, deviating from the recommendation silently, and rounding up to PATCH_DONE on partial success.
- **QA outcome-based feature definition clarified** — references the SKILL.md `## Concepts` definition rather than restating it inline, ensuring consistency.
- **Template cleanup** — placeholder `## Dev outcome (attempt 1)` and `## QA/Patch outcome (attempt 1)` sections removed from feature.md and defect.md templates; these sections are written by personas, not pre-scaffolded.

## [0.6.0] — 2026-04-03

### Added
- **Architect dev brief** — architect (pre-dev) now writes an `## Architect brief` section to the `.mash/dev/` feature file: implementation directives, extension guidance, and gap resolutions. Dev reads this as binding guidance before writing code.
- **Architect updates architecture.md for extensions** — EXTENSION items (new patterns not yet documented) are written directly to `architecture.md` by the architect before dev starts, so the decision is established and visible to future features.
- **Architect proposes architecture.md edits for conflicts** — for each CONFLICT, architect produces a proposed `architecture.md` edit alongside the conflict description.
- **MASH ARCH_FAIL: Update architecture.md option** — ARCH_FAIL user prompt gains a 4th option: apply the architect's proposed edit to `architecture.md` and re-run the pre-dev check.

### Changed
- **Global installation** — MASH skill files are now installed globally instead of per-project. Claude Code skill lives in `~/.claude/skills/mash/`; opencode skill in `~/.config/opencode/skills/mash/` (auto-discovered). The `/mash` command is registered globally at `~/.claude/commands/mash.md`. Projects no longer contain `skills/mash/` or `.opencode/` directories.
- **Migration support** — installer automatically detects and cleans up old local installations (`skills/mash/`, `.opencode/skills/`, `.opencode/commands/`, `.claude/commands/mash.md`) before installing globally.
- **opencode.json simplified** — now contains permissions only; skills path config removed (opencode auto-discovers from global `~/.config/opencode/skills/`).
- **Init bootstraps scaffolding** — `/mash init` now creates `.mash/` directory structure if missing, enabling use in fresh projects without running the installer first.

## [0.5.0] — 2026-04-02

### Added
- **Milestone smoke test** — after all features reach DONE, MASH re-runs every Verification Step from every completed feature in sequence through the application's real environment (Docker/docker-compose if applicable). Log output is collected and inspected; any failures are filed as defects before completion is reported.
- **Application startup check (QA)** — before writing any tests, the QA agent now attempts to start the application through its primary entry point (respecting Docker/docker-compose if specified in architecture.md), collects logs, and sets `QA_FAIL` immediately if the application fails to start or logs errors. Tests are not written against a fundamentally broken application.
- **End-to-end application check (Dev)** — after running per-feature Verification Steps, the dev agent now runs the full application in a representative end-to-end scenario, checks logs for errors, and must fix any failures before setting `DEV_DONE`. A feature that passes its isolation checks but breaks the running application is not done.
- **Docker/log awareness** — all verification phases (dev self-check, QA startup check, milestone smoke test) now check architecture.md for the intended run environment and use `docker compose logs` / `docker logs` where applicable. Log errors are treated as failures even when exit codes are 0.

### Changed
- **Verification Step template hardened** — feature.md template comment now gives explicit quality criteria: steps must use the user-facing entry point (not internal imports), check actual output content (not just exit codes), and include at least one representative end-to-end scenario. Includes a bad/good example.
- **opencode install is now self-contained under `.opencode/`** — `skills/mash/` is no longer installed for opencode users. opencode gets its own copy of SKILL.md (inlined with path rewriting) and all references under `.opencode/skills/mash/`. This removes the cross-directory indirection that caused weaker models to fail skill loading.

### Fixed
- **Fix persona defect ID collision** — fix persona now uses the maximum existing defect ID (not count) to generate the next ID, preventing collisions when defects have been deleted or are non-contiguous.

## [0.4.8] — 2026-04-02

### Fixed
- **opencode skill redirect** — installer now inlines the full `skills/mash/SKILL.md` content into `.opencode/skills/mash/SKILL.md` (using opencode frontmatter + main body) instead of a redirect. Non-Anthropic models in opencode no longer need to follow a "Use the Read tool" instruction to load the skill.

## [0.4.7] — 2026-04-01

### Changed
- **Feature tracking overhaul** — numbered retry outcome sections (`## Dev outcome (attempt N)`, `## QA outcome (attempt N)`, `## Patch outcome (attempt N)`) replace anonymous repeated headers, making retry history unambiguous. Failure-handling sync step now explicitly preserves outcome sections when updating spec content. Plan file template no longer carries `status`/`attempt` fields (dev-only); dev copy adds them on creation.
- **`WIP` visibility** — dashboard and `/mash status` now show the dev file status in parentheses for WIP features (e.g. `WIP (DEV_DONE)`), giving users pipeline visibility without format changes.
- **CONFIGURE SETTINGS extracted** — git workflow and sub-agent permissions configuration is now a shared `CONFIGURE SETTINGS` procedure in SKILL.md, called by both the `config` command and init-persona Phase 1. Eliminates ~30 lines of duplicated logic; CONFIG's `Stop` no longer breaks the init flow.
- **SKILL.md deduplication** — branch setup logic extracted to a shared `BRANCH SETUP(<type>, <id>)` procedure; `dev` and `fix` command entries consolidated.

## [0.4.5] — 2026-04-01

### Changed
- **opencode skill loading** — `opencode-commands/mash.md` now references `skills/mash/SKILL.md` directly (was `.opencode/skills/mash/SKILL.md`), cutting one indirection hop. Both opencode files now use explicit "Use the Read tool on ... directly" phrasing to prevent weaker models from globbing before reading.
- **Installer scaffolding** — removed `src/` and `tests/` from scaffolded directories; these are project-specific and should not be imposed by the installer.
- **Installer `.gitignore`** — added `skills/mash/` to the gitignore entries written on install, treating it as a managed dependency (like `node_modules/`).

## [0.4.3] — 2026-04-01

### Fixed
- **`/mash config` opencode sync** — permission display now shows separate sections for `.claude/settings.local.json` (Bash, Edit, Write) and `opencode.json` (bash, edit, webfetch), shown only when each file exists. "Reapply permissions" option label no longer hardcodes `.claude/settings.local.json`. Reapply handler now checks `webfetch` for opencode and uses `.opencode/` directory detection for fallback config creation, matching init-persona behavior from 0.4.1.

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
