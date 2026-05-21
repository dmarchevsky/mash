# MASH: fix

Collaborative debugging session followed by automated patching.

**Arguments**:
- `fix` — interactive debugging session, then patch
- `fix <description>` — pre-seed the defect summary; skip "what went wrong?"
- `fix <id>` — retry a previously logged defect by ID; skip intake, go straight to PATCH LOOP

**CRITICAL**: Even if the root cause is immediately obvious from the user's description, you MUST run fix-persona through all phases. Do not analyze the bug, propose the fix, or write or suggest any code change yourself — that is patch-persona's job, invoked as a sub-agent after the defect file is written. The intake process is mandatory, not optional.

## CHECK INIT

Check that `.mash/plan/project.md`, `.mash/plan/architecture.md`, `.mash/plan/settings.md`, `.mash/plan/progress.md`, `.mash/plan/features/`, and `.mash/dev/` all exist and have content beyond templates. If any are missing or empty, ask the user if they want to initialize first.

## Argument Dispatch

- If argument is a single integer (e.g. `fix 1`): skip to PATCH LOOP to retry that defect.
- Otherwise (no args or text description): run INVOKE FIX below, then PATCH LOOP.

## INVOKE FIX

Immediately after greeting, output this line before doing anything else:
> "Starting fix intake — this will take a few turns before any patching begins. I won't touch any code until patch-persona is invoked as a sub-agent."

Read `skills/mash/references/fix-persona.md` and **execute its instructions directly** in the current conversation. Do NOT spawn a sub-agent — debugging requires multi-turn interaction with the user via AskUserQuestion.

Pass any inline description (the non-integer arguments) to fix-persona as the pre-seeded Summary.

After fix-persona completes and writes `.mash/dev/defect-<id>.md`, **immediately proceed to PATCH LOOP**. Do NOT stop.

## PATCH LOOP

Read `skills/mash/shared/patch-loop.md` and follow its instructions for the defect.
