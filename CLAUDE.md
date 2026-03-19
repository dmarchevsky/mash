# MASH — Markdown Agile Sub-agent Hybrid

This project uses the MASH framework for planning and implementation.

## Conventions

- **`.planning/`** is the source of truth for all specs, stories, and architecture decisions.
- **`src/`** contains application source code.
- **`tests/`** contains test files.
- Story files live in `.planning/stories/` with YAML frontmatter tracking status.
- The MASH orchestrator skill (`.claudecode/mash-orchestrator/SKILL.md`) manages planning and delegates implementation to isolated sub-agents.

## Workflow

1. Use the `mash` skill to plan features (breaks work into stories).
2. Use `mash run <story-id>` to execute a dev→QA loop for a story.
3. The orchestrator never writes code directly — it spawns sub-agents.
