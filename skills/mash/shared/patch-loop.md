# PATCH LOOP

Process a defect through the patch/QA cycle. Before starting, read `skills/mash/shared/status-reference.md` for status codes and safety rules.

1. **Validate**: Check `.mash/dev/defect-<id>.md` exists. If not, tell the user to run `/mash fix` first and stop.
2. **Branch setup**: Read `skills/mash/shared/branch-setup.md` and follow it with `type=defect`, `id=<id>`.
3. **Read status** from `.mash/dev/defect-<id>.md` and route using this table:

| Status | Action |
|--------|--------|
| DEV_READY | Go to step 4. |
| WIP | Go to step 4. |
| PATCH_DONE | Set status to `DEV_DONE` in the defect file, then skip to step 6 (QA phase). |
| PATCH_FAIL | Go to step 8 (failure handling). |
| QA_FAIL | Go to step 8 (failure handling). |
| QA_PASS | Go to step 7 (post-fix completion). |

4. **Increment attempt**: Update `attempt` in frontmatter. If attempt > 3, report FAILED to the user and use AskUserQuestion: *"Defect <id> failed after 3 attempts. Clean up worktree now? (Keeping it lets you inspect the failed work.)"* If yes, run WORKTREE CLEANUP (see `skills/mash/shared/post-feature.md`). Stop.

5. **INVOKE PATCH**: **If this is a retry (attempt > 1):** Read the `## Patch outcome (attempt <n-1>)` section in `.mash/dev/defect-<id>.md`. Extract the blocker or failure summary. Append a RETRY CONTEXT block:
```
---
RETRY CONTEXT (attempt <n> of 3):
Previous attempt ended with: <PATCH_FAIL or QA_FAIL>
Blocker: <one-line blocker from the previous MASH_STATUS block or outcome section>
The Patch outcome (attempt N) section(s) in the defect file record what was tried. Read them before proceeding — do not repeat a failed approach.
```

**Lesson injection:** If `.mash/plan/lessons.md` exists and contains lesson entries, read it and select up to 5 lessons relevant to this defect (by keyword match against the defect Summary, Root Cause Hypothesis, Fix Recommendation, and feature_ref if set). If relevant lessons are found, append a LESSONS CONTEXT block:
```
---
LESSONS CONTEXT:
These lessons were learned from previous features and defects in this project. Apply them where relevant — they reflect real issues encountered in this codebase.
<list of selected lessons, one per line, format: "- L-NNN [type]: lesson text">
---
```

Read `skills/mash/references/patch-persona.md` and invoke:
```
Agent(
  prompt="<patch-persona.md contents>

---
PARAMETERS:
- defect_file: .mash/dev/defect-<id>.md

Read these files before starting:
- .mash/plan/architecture.md
- .mash/plan/project.md
- .mash/dev/defect-<id>.md

<If LESSONS CONTEXT — append it here>
<If branching: worktree — read skills/mash/shared/worktree-context.md, use the impl template, substitute type=defect, id=<id>, and append it here>"
)
```
After the agent returns, read the `---MASH_STATUS---` block in the agent output to get the status directly. If the block is absent, fall back to reading `.mash/dev/defect-<id>.md`.

Go back to step 3.

6. **QA phase**: Read `skills/mash/shared/invoke-qa.md` and follow it with `type=defect`, `id=<id>`. After it returns, go back to step 3.

7. **Post-fix completion** (QA_PASS):
   1. Read `skills/mash/shared/invoke-architect.md` and run post-qa mode for this defect.
   2. If ARCH_FAIL, present gaps to the user via AskUserQuestion (same three options as described in invoke-architect.md post-qa section).
   3. Present QA outcome to the user. Use AskUserQuestion to confirm the fix is resolved.
   4. Read `skills/mash/shared/extract-lessons.md` and follow its instructions for this defect.
   5. If `git: none` in settings.md, skip git operations. Otherwise:
      - Stage all changes: run `git add -A` from within the worktree if `branching: worktree`, or from the project root if `branching: current_branch`.
      - Commit with a descriptive message referencing the defect: run `git commit` from the same location.
      - If `commit: auto` and `branching: worktree`: switch to the original branch (`git checkout <original_branch>` from project root), then merge: `git merge mash/defect-<id> --no-ff`. If the merge produces conflicts, stop and inform the user with the conflicting files listed — do NOT run WORKTREE CLEANUP. Ask the user to resolve conflicts, then confirm to proceed with cleanup.
   6. Run WORKTREE CLEANUP (see `skills/mash/shared/post-feature.md`) if applicable.
   7. Stop.

8. **Failure handling** (PATCH_FAIL or QA_FAIL): Read `skills/mash/shared/failure-classification.md` and classify. For defects:
   - **Implementation bug**: propose targeted changes to the Fix Recommendation and retry.
   - **Approach failure**: update the defect file's Root Cause Hypothesis and Fix Recommendation. Log the failed approach in Debugging Notes.
   - Present proposed changes to the user for review and confirmation via AskUserQuestion.
   - Apply confirmed changes to the defect file. **Preserve all `## Patch outcome (attempt N)` and `## QA outcome (attempt N)` sections exactly as they are** — only update spec sections (Root Cause Hypothesis, Fix Recommendation, Debugging Notes).
   - Set status to `DEV_READY`.
   - Go back to step 3.
