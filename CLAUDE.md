# MASH — Markdown Agile Sub-agent Hybrid

This project uses the MASH framework for planning and implementation.

## Conventions

- **`.planning/`** is the source of truth for all specs, stories, and architecture decisions.
- **`src/`** contains application source code.
- **`tests/`** contains test files.
- Story files live in `.planning/stories/` with YAML frontmatter tracking status.
- The MASH skill (`.claudecode/mash/SKILL.md`) manages planning and delegates implementation to isolated sub-agents.

## Workflow

1. `mash init` — iteratively define your project (architecture + scope).
2. `mash plan` — interactively create user stories with clarifying questions.
3. `mash dev <story-id>` or `mash dev-all` — implement and test stories via sub-agents.
4. MASH never writes code directly — it spawns sub-agents.
