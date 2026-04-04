# MASH — Multi-Agent Software Harness

MASH is a framework for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and [opencode](https://opencode.ai) that orchestrates multiple AI personas to plan, implement, and verify software features. Instead of writing code in a single conversation, MASH separates concerns into specialized agents — each with strict read/write boundaries — and manages the full lifecycle from idea to tested code.

## How It Works

MASH uses seven specialized personas:

```
  You ──► /mash init ──► Init Agent       → defines project scope & architecture
       ──► /mash plan ──► Plan Agent      → turns ideas into detailed feature specs
       ──► /mash dev  ──► Architect Agent → checks spec against architecture (pre-dev)
                       ──► Dev Agent(s)   → implements features autonomously
                       ──► QA Agent(s)    → writes and runs tests to verify
                       ──► Architect Agent→ verifies QA evidence covers stated goals (post-qa)
       ──► /mash fix  ──► Fix Agent       → collaborative debugging with the user
                       ──► Patch Agent    → minimal-change fix implementation
```

**Init**, **Plan**, and **Fix** run interactively in your conversation, asking clarifying questions. **Dev**, **QA**, **Patch**, and **Architect** are spawned as isolated sub-agents that work autonomously within defined boundaries.

## Installation

Requires [Claude Code](https://docs.anthropic.com/en/docs/claude-code) or [opencode](https://opencode.ai) and Git. Works on Linux, macOS, and Windows (via [Git Bash](https://git-scm.com/downloads)).

Interactive installer:
```bash
bash <(curl -sL https://raw.githubusercontent.com/dmarchevsky/mash/main/install.sh)
```

Target a specific client (non-interactive):
```bash
curl -sL https://raw.githubusercontent.com/dmarchevsky/mash/main/install.sh | bash -s -- --claude
curl -sL https://raw.githubusercontent.com/dmarchevsky/mash/main/install.sh | bash -s -- --opencode
```

The installer detects which AI client(s) are available and installs MASH globally — no per-project skill copies needed. If both are installed and no flag is given, it prompts you to choose. MASH is registered as a `/mash` slash command in both clients.

**Claude Code (global):**
- `~/.claude/mash/` — framework files (orchestrator, personas, templates)
- `~/.claude/commands/mash.md` — `/mash` slash command entry point

**opencode (global):**
- `~/.config/opencode/mash/` — framework files
- `~/.config/opencode/commands/mash.md` — `/mash` slash command entry point

**Per project:**
- `.mash/plan/` — where specs and feature definitions live

Existing files are preserved. The installer only adds scaffolding for directories that don't exist yet. Running it in subsequent projects skips the global install if already up to date.

## Quick Start

```
/mash init          # Define your project, tech stack, and git workflow
/mash plan          # Describe features — MASH asks questions, writes specs
/mash dev           # Implement all ready features (dev + QA agents)
```

## Commands

| Command | Description |
|---------|-------------|
| `/mash` | Show dashboard with feature status and next steps |
| `/mash init` | Interactively define project scope, architecture, and settings |
| `/mash init <filename>` | Same, but seeds the conversation from an existing project description file |
| `/mash plan` / `/mash plan <desc>` | Create new feature specifications through guided conversation |
| `/mash plan <id>` | Redefine an existing feature spec interactively, then reimplement it |
| `/mash dev` | Implement and test all DEV_READY features |
| `/mash dev 1,3` | Implement specific features by ID; if a feature is already DONE, offers reimplementation |
| `/mash fix` | Debug a defect collaboratively, then patch and verify |
| `/mash fix <id>` | Retry a previously logged defect by ID |
| `/mash fix <desc>` | Debug with a pre-seeded description |
| `/mash config` | View or change git settings and sub-agent permissions |
| `/mash status` | Show current progress table |
| `/mash update` | Check for and install framework updates |

## Architecture

### Personas

Each persona has a defined role and strict file access boundaries:

| Persona | Role | Reads | Writes |
|---------|------|-------|--------|
| **Init** | Define project scope and technical decisions | Filesystem scan | `.mash/plan/project.md`, `architecture.md`, `settings.md`, `progress.md` |
| **Plan** | Turn ideas into detailed, testable feature specs | All plan files, `src/` | `.mash/plan/features/feature-<id>.md`, `progress.md` |
| **Architect** | Verify spec-architecture alignment (pre-dev) and QA goal coverage (post-qa) | Plan files, dev/defect file | `.mash/dev/feature-<id>.md` (dev brief, pre-dev mode), `.mash/plan/architecture.md` (EXTENSION decisions, pre-dev mode) |
| **Dev** | Implement a single feature according to spec | Plan files (read-only) | `src/`, `.mash/dev/feature-<id>.md` |
| **QA** | Verify implementation through tests; checks application starts before writing any tests | Plan files, `src/` (read-only) | `tests/`, `.mash/dev/feature-<id>.md` |
| **Fix** | Collaborative debugging with the user | Project context, `src/` | `.mash/dev/defect-<id>.md` |
| **Patch** | Minimal-change fix implementation | Everything (read-only except defect file) | `src/`, `.mash/dev/defect-<id>.md` |

### Feature Lifecycle

```
CREATED ──► DEV_READY ──► WIP ──► DEV_DONE ──► QA_PASS ──► ARCH_VERIFIED ──► DONE
                           │         │            │               │
                           └─────────┴────────────┴───────────────┘
                                        retry (up to 3x)
                                               │
                                            FAILED
```

Each feature passes through two architect gates: a **pre-dev** check (spec vs. architecture) before implementation starts, and a **post-qa** check (QA evidence vs. stated goals) before the feature is marked DONE.

Once all features reach DONE, MASH runs a **milestone smoke test** — re-running every Verification Step from every feature in the application's real environment (including Docker if applicable), with log inspection. Any failures are filed as defects before completion is reported.

Features are tracked in `.mash/plan/progress.md` and defined as individual spec files in `.mash/plan/features/` with YAML frontmatter:

```yaml
---
id: 1
title: User Authentication
---
```

Each spec includes a description, acceptance criteria, verification steps (exact commands proving the feature works through its user-facing entry point), regression tests, and technical notes.

### Git Workflow Options

Configured during `mash init` (saved to `.mash/plan/settings.md`):

**Branching:**
- `worktree` — each feature gets a `mash/feature-<id>` branch in a git worktree, merged on completion
- `current_branch` — all work happens directly on the current branch

**Commits:**
- `auto` — MASH commits after the architect verifies QA coverage and merges worktree branches
- `manual` — you handle all git operations yourself

### Project Structure

**Global (installed once, shared across all projects):**
```
~/.claude/
├── commands/mash.md                   # /mash slash command entry point
└── mash/                              # Framework files
    ├── SKILL.md                       #   Orchestrator
    ├── VERSION
    └── references/                    #   All personas and templates

~/.config/opencode/
├── commands/mash.md                   # /mash slash command entry point
├── config.json                        # external_directory permission pre-approved
└── mash/                              # Framework files
    ├── SKILL.md
    ├── VERSION
    └── references/
```

**Per project:**
```
your-project/
├── .claude/
│   └── settings.local.json            # Sub-agent permissions (Claude Code)
├── opencode.json                      # Sub-agent permissions (opencode)
├── CLAUDE.md                          # MASH invocation instructions (injected)
├── .mash/
│   ├── plan/                          # Source of truth (specs, architecture)
│   │   ├── project.md
│   │   ├── architecture.md
│   │   ├── settings.md
│   │   ├── progress.md
│   │   └── features/
│   │       └── feature-1.md
│   └── dev/                           # Working copies (gitignored)
├── src/                               # Application code (written by dev agents)
└── tests/                             # Test code (written by QA agents)
```

## Updating

```
/mash update
```

Or manually:

```bash
bash <(curl -sL https://raw.githubusercontent.com/dmarchevsky/mash/main/install.sh)
```

Use `--force` to reinstall the current version:

```bash
curl -sL https://raw.githubusercontent.com/dmarchevsky/mash/main/install.sh | bash -s -- --force
```

## Why MASH over alternatives?

Several frameworks exist for orchestrating AI-driven development with Claude Code. Here's how MASH compares to two popular ones.

### vs. [GSD (Get Shit Done)](https://github.com/gsd-build/get-shit-done)

GSD is a context-engineering framework focused on preventing context window degradation. It uses ~40+ slash commands, XML-structured prompts, and an elaborate pipeline of specialized sub-agents (researchers, planners, checkers, executors, verifiers).

**Where MASH differs:**

- **Simplicity over configuration.** MASH has 8 commands. GSD has 40+. MASH's workflow is clear from day one — you don't need to learn modes, profiles, granularity settings, or branching templates.
- **Interactive planning, not automated research.** GSD spawns 4 parallel research agents to investigate your stack before planning. MASH's plan persona talks *to you* — asking clarifying questions across multiple rounds to capture intent that no amount of automated research can surface.
- **Clean separation of concerns.** MASH personas have strict read/write boundaries enforced by the framework. Dev agents can't touch specs. QA agents can't touch source code. GSD's agents are role-typed but share broader access.
- **Minimal file footprint.** GSD generates `PROJECT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`, research directories, context files, summaries, todos, threads, and seeds. MASH keeps everything in `.mash/plan/` — a handful of markdown files.
- **No dangerous permissions required.** GSD recommends `--dangerously-skip-permissions` for frictionless automation. MASH works within Claude Code's standard permission model.
- **Integrated QA with retry logic.** MASH runs a dedicated QA agent after every dev agent, with automatic retry (up to 3 attempts) and failure analysis. GSD treats testing as a post-hoc verification/UAT phase.

### vs. [Superpowers](https://github.com/obra/superpowers)

Superpowers is a composable skills plugin that enforces mandatory process guardrails — brainstorming, strict TDD, two-stage code review. Skills trigger automatically; the agent "just has superpowers."

**Where MASH differs:**

- **Structured end-to-end execution with gateways.** Superpowers enhances how the agent behaves within a single conversation. MASH manages the full pipeline — spec → dev agent → QA agent → commit/merge — with explicit gateway checks between each stage. A feature doesn't advance from dev to QA without passing validation, and doesn't reach DONE without passing QA. This is an execution framework, not a behavior modifier.
- **Explicit feature tracking.** MASH maintains a progress table with status transitions (CREATED → DEV_READY → WIP → DONE/FAILED), attempt counts, and dev/QA outcomes. Superpowers has no equivalent project-level feature tracker.
- **Built-in retry on failure.** When a MASH dev or QA agent fails, the failure analysis is fed back into the next attempt with updated context. Superpowers has systematic debugging but no automatic retry loop for feature implementation.

## Design Principles

- **Separation of concerns** — each persona has a single responsibility and limited file access
- **Specs are the source of truth** — `.mash/plan/` is read-only during implementation
- **Interactive planning** — init and plan personas ask multiple rounds of questions before writing specs
- **Autonomous execution** — dev and QA agents work independently within their boundaries
- **Retry with context** — failed features are retried up to 3 times with failure analysis fed back to the next attempt
- **Application-level verification** — dev must run the full application end-to-end before marking a feature done; QA checks the app starts before writing tests; a milestone smoke test confirms the whole application works after all features land
- **Framework, not boilerplate** — MASH manages the process; your project's code, structure, and tools are entirely up to you

## License

MIT
