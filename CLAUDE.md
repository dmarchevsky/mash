# MASH — Markdown Agile Sub-agent Hybrid

This project uses the MASH framework for planning and implementation.

## Conventions

- **`.mash/plan/`** is the source of truth for all specs, features, and architecture decisions.
- **`src/`** contains application source code.
- **`tests/`** contains test files.
- Feature files live in `.mash/plan/features/` with YAML frontmatter tracking status.
- The MASH skill (`.claudecode/mash/SKILL.md`) manages planning and delegates implementation to isolated sub-agents.

## Workflow

1. `mash init` — iteratively define your project (architecture + project).
2. `mash plan` — interactively create features with clarifying questions.
3. `mash dev <feature-id>` or `mash dev-all` — implement and test features via sub-agents.
4. MASH never writes code directly — it spawns sub-agents.
