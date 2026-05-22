# IMPLEMENTATION LOOP

Process each feature to implement. Before starting, read `${CLAUDE_SKILL_DIR}/shared/status-reference.md` for status codes and safety rules.

For each feature:

1. **Validate**: Check `.mash/plan/features/feature-<id>.md` exists and has valid content. If not, stop.
2. **Check progress.md entry**: If no entry exists, stop.
3. **Branch setup**: Read `${CLAUDE_SKILL_DIR}/shared/branch-setup.md` and follow it with `type=feature`, `id=<id>`.
4. **Prepare dev copy**: If `.mash/dev/feature-<id>.md` does not exist, copy it from `.mash/plan/features/feature-<id>.md` and **add** `status: DEV_READY` and `attempt: 0` to the dev copy frontmatter (the plan file does not contain these fields).
5. **Read dev status** from `.mash/dev/feature-<id>.md` and route using this table:

| Status | Action |
|--------|--------|
| CREATED | Skip this feature (should not be in dev with this status). |
| DONE | Ask user: "Feature <id> is already done. Reimplement from scratch?" If no, skip. If yes, run REIMPLEMENTATION SETUP below, then go to step 6. |
| DEV_READY | Go to step 6. |
| WIP | Go to step 6. |
| DEV_DONE | Skip to step 8 (QA phase). |
| DEV_FAIL | Go to step 9 (failure handling). |
| QA_FAIL | Go to step 9 (failure handling). |
| QA_PASS | Read `${CLAUDE_SKILL_DIR}/shared/invoke-architect.md` and run post-qa mode. If ARCH_VERIFIED, mark DONE in progress.md and run POST-FEATURE. |

#### REIMPLEMENTATION SETUP
1. Set status to `DEV_READY` in `.mash/dev/feature-<id>.md`.
2. Set `attempt` to `0` in the frontmatter (step 6 will increment it to 1).
3. Set progress.md status to `WIP`.
4. Set a `reimplementation: true` flag (in memory, not in the file) so the architect receives REIMPLEMENTATION CONTEXT.
5. Continue to step 6.

6. **Increment attempt**: Update the `attempt` field in `.mash/dev/feature-<id>.md` frontmatter. If attempt > 3, set progress.md status to FAILED and use AskUserQuestion: *"Feature <id> failed after 3 attempts. Clean up worktree now? (Keeping it lets you inspect the failed work.)"* If yes, run WORKTREE CLEANUP (see `${CLAUDE_SKILL_DIR}/shared/post-feature.md`). Stop this feature.
7. **Set progress.md to WIP.**

Read `${CLAUDE_SKILL_DIR}/shared/invoke-architect.md` and run **pre-dev** mode for this feature before proceeding to dev.

#### INVOKE DEV

**If this is a retry (attempt > 1):** Read the `## Dev outcome (attempt <n-1>)` section in `.mash/dev/feature-<id>.md`. Extract the blocker or failure summary. Append a RETRY CONTEXT block to the agent prompt:
```
---
RETRY CONTEXT (attempt <n> of 3):
Previous attempt ended with: <DEV_FAIL or QA_FAIL>
Blocker: <one-line blocker from the previous MASH_STATUS block or outcome section>
The Dev outcome (attempt N) section(s) in the feature file record what was tried. Read them before choosing your approach — do not repeat a failed approach.
```

**Lesson injection:** If `.mash/plan/lessons.md` exists and contains lesson entries, read it and select up to 5 lessons relevant to this feature (by keyword match against the feature description, acceptance criteria, technical notes, and dependency chain). If relevant lessons are found, append a LESSONS CONTEXT block:
```
---
LESSONS CONTEXT:
These lessons were learned from previous features and defects in this project. Apply them where relevant — they reflect real issues encountered in this codebase.
<list of selected lessons, one per line, format: "- L-NNN [type]: lesson text">
---
```

Read `${CLAUDE_SKILL_DIR}/references/dev-persona.md` and invoke the Agent tool with both required parameters (`description` and `prompt`):
```
Agent(
  description="MASH Dev agent",
  prompt="<dev-persona.md contents>

---
PARAMETERS:
- feature_file: .mash/dev/feature-<id>.md

Read these files before starting:
- .mash/plan/architecture.md
- .mash/plan/project.md
- .mash/dev/feature-<id>.md

<If LESSONS CONTEXT — append it here>
<If branching: worktree — read ${CLAUDE_SKILL_DIR}/shared/worktree-context.md, use the impl template, substitute type=feature, id=<id>, and append it here>"
)
```
After the agent returns, read the `---MASH_STATUS---` block in the agent output to get the status directly. If the block is absent, fall back to reading `.mash/dev/feature-<id>.md`. **If status is DEV_DONE, validate verification evidence:** check `verified_steps` in the MASH_STATUS block — if not all steps have evidence, or if the block is absent and the Dev outcome section lacks command + actual output for each Verification Step, set status back to DEV_READY and re-invoke dev with a note that verification evidence is required for each step. Go back to step 5.

8. **QA phase**: Read `${CLAUDE_SKILL_DIR}/shared/invoke-qa.md` and follow it with `type=feature`, `id=<id>`. After it returns, go back to step 5.

9. **Failure handling** (DEV_FAIL or QA_FAIL): Read `${CLAUDE_SKILL_DIR}/shared/failure-classification.md` and classify. For features:
   - Propose changes to `.mash/plan/features/feature-<id>.md` and/or `.mash/plan/architecture.md` based on failure type.
   - Present proposed changes to the user for review and confirmation.
   - Apply confirmed changes to the plan feature file.
   - **Sync spec sections to dev file**: update only the spec sections (Description, Acceptance Criteria, Verification Steps, Technical Notes) in the dev file with the updated content from the plan file. **Preserve all `## Dev outcome (attempt N)` and `## QA outcome (attempt N)` sections in the dev file exactly as they are.**
   - Set dev feature file status to DEV_READY.
   - Go back to step 5.

## Loop Completion

After processing a feature:
- Check progress.md for remaining incomplete features.
- If more remain: proceed to next feature in the loop.
- If none remain: run **MILESTONE SMOKE TEST** below, then create a summary report for the user and stop.

### MILESTONE SMOKE TEST

Run after all features in the current milestone are marked `DONE`, before reporting completion to the user. By this point all worktrees have been merged and cleaned up — run all verification from the project root.

1. Collect all Verification Steps from all completed feature files in `.mash/dev/`.
2. **Check architecture.md for how the application is meant to run** (local process, Docker, docker-compose, etc.).
3. Run each Verification Step in sequence through the application's user-facing entry point — not through internal imports or the test harness. **Run in the application's intended environment** (Docker/docker-compose if applicable).
4. **After each run, check logs**: `docker compose logs`, `docker logs <container>`, or stdout/stderr. Record errors, panics, or unexpected warnings alongside the command output.
5. Record pass/fail for each step.
6. If any step fails or logs contain errors:
   - Present the failures to the user.
   - For each failure, offer to file a defect using the standard defect flow.
   - Do not report the milestone as complete until failures are resolved.
7. If all steps pass and logs are clean, report the milestone complete with the smoke test output and a log summary as evidence.
