# MASH: plan

> **Path note**: `.mash/` paths below are in the user's project directory (CWD), not in this framework's install directory.

Create or refine feature specifications.

**Arguments**: optional `<description>` — an inline feature description to pre-seed the conversation.

> **Note**: If the argument is a single integer (e.g. `plan 2`), you should NOT be reading this file — the dispatcher should have routed to `commands/dev.md` with `plan_id` set. If you're here with an integer argument, read `${CLAUDE_SKILL_DIR}/commands/dev.md` instead and pass the integer as `plan_id`.

## Steps

1. **CHECK INIT**: Check that `.mash/plan/project.md`, `.mash/plan/architecture.md`, `.mash/plan/settings.md`, `.mash/plan/progress.md`, `.mash/plan/features/`, and `.mash/dev/` all exist and have content beyond templates. If any are missing or empty, ask the user if they want to initialize first.

2. Read `${CLAUDE_SKILL_DIR}/references/plan-persona.md` and **execute its instructions directly** in the current conversation. Do NOT spawn a sub-agent — plan requires multi-turn interaction with the user via AskUserQuestion.

3. If the user provided an inline description (e.g. `mash plan build a site checker`), pass it to plan-persona as the pre-seeded feature description. Plan-persona should skip asking "what do you want to build?" and begin Phase 1 with this description already in hand — treating it as the user's initial answer and proceeding directly to follow-up clarifying questions.

**After plan-persona completes, stop.**
