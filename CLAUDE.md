<!-- MASH -->
# MASH — Multi-Agent Software Harness

This project uses the MASH framework for planning and implementation.

## Conventions

- **`.mash/plan/`** is the source of truth for all specs, features, and architecture decisions.
- **`src/`** contains application source code.
- **`tests/`** contains test files.
- Feature specs live in `.mash/plan/features/` with YAML frontmatter tracking status.
- Working copies for implementation live in `.mash/dev/`.
- `.mash/plan/progress.md` is the main status tracker.
- The MASH skill (`.claude/mash/SKILL.md`) manages planning and delegates implementation to isolated sub-agents via the Agent tool.

## Workflow

1. `mash init` — iteratively define your project (architecture + project).
2. `mash plan` — interactively create features with clarifying questions.
3. `mash dev [feature-ids]` — implement and test features via sub-agents (dev-persona then qa-persona).
4. `mash update` — check for and install framework updates.
5. `mash status` — show current progress.
6. MASH never writes code directly — it spawns sub-agents.
<!-- /MASH -->
