# MASH: dev

Implement features through the full dev/QA cycle.

**Arguments**:
- `dev` — implement all non-DONE features
- `dev 1,3` — implement only the specified features (comma-separated IDs)
- Called with `plan_id=<N>` — redefine feature N, then implement it (from `mash plan <id>`)

## CHECK INIT

Check that `.mash/plan/project.md`, `.mash/plan/architecture.md`, `.mash/plan/settings.md`, `.mash/plan/progress.md`, `.mash/plan/features/`, and `.mash/dev/` all exist and have content beyond templates. If any are missing or empty, ask the user if they want to initialize first.

## DEV PLAN FLOW (only if plan_id is set)

If `plan_id` is set, this is a replan-then-implement flow. Do NOT stop between planning and implementation.

1. **Validate**: Check `.mash/plan/features/feature-<plan_id>.md` exists. If not, report error and stop.
2. **Check progress.md**: feature `<plan_id>` must have an entry. If missing, add it with status `CREATED`.
3. Read `.mash/plan/features/feature-<plan_id>.md`.
4. **Run plan-persona in replan mode**:
   - Read `skills/mash/references/plan-persona.md` and **execute its instructions directly** in the current conversation. Do NOT spawn a sub-agent — plan requires multi-turn interaction with the user via AskUserQuestion.
   - Provide plan-persona with:
     - `replan_mode: true`
     - `feature_file: .mash/plan/features/feature-<plan_id>.md`
   - Plan-persona will update the existing feature file in place (not create a new one).
5. **Sync dev file** after plan-persona completes:
   - If `.mash/dev/feature-<plan_id>.md` exists:
     - Overwrite only the spec sections (Description, Acceptance Criteria, Verification Steps, Regression Tests, Technical Notes) with the updated content from the plan file.
     - Preserve all `## Dev outcome (attempt N)` and `## QA outcome (attempt N)` sections exactly as they are.
     - Set `status: DEV_READY` and `attempt: 0` in the frontmatter.
   - If the dev file does not exist: do nothing — the implementation loop will create it.
6. **Set progress.md status to `WIP`**.
7. Set `reimplementation: true` flag (in memory, not in any file) for the architect.
8. Proceed directly to IMPLEMENTATION LOOP for feature `<plan_id>` only.

## PREPARE FOR IMPLEMENTATION (only if plan_id is NOT set)

If the user specified feature IDs, consider only those features. Otherwise consider all non-DONE features.

1. Read `.mash/plan/progress.md`, `.mash/plan/project.md`, `.mash/plan/architecture.md`, `.mash/plan/settings.md`.
2. For each feature being considered:
   - If it has no entry in progress.md, add it with status CREATED.
3. Read all feature files with CREATED status. Verify they are complete and consistent with project.md and architecture.md.
4. Check that dependencies between features allow development in the defined order. Rearrange if needed.
5. If issues found that need user input, ask the user before proceeding.
6. Set all validated CREATED features to DEV_READY in progress.md.

## IMPLEMENTATION LOOP

Read `skills/mash/shared/implementation-loop.md` and follow its instructions for each feature to implement.

When the implementation loop calls POST-FEATURE, read `skills/mash/shared/post-feature.md` and follow its instructions.
