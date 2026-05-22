# INVOKE QA

Used by both the implementation loop (features) and patch loop (defects). Called with `type` (`feature` or `defect`) and `id`.

Before invoking for a defect, ensure the defect file status is `DEV_DONE` (patch-persona sets PATCH_DONE; translate this to DEV_DONE so qa-persona proceeds correctly).

Read `${CLAUDE_SKILL_DIR}/references/qa-persona.md` and invoke the Agent tool with both required parameters (`description` and `prompt`):
```
Agent(
  description="MASH QA agent",
  prompt="<qa-persona.md contents>

---
PARAMETERS:
- feature_file: .mash/dev/<type>-<id>.md

<If type=defect — append:>
IMPORTANT — defect file structure:
This is a defect file, not a feature file. When the qa-persona instructions reference feature sections, substitute as follows:
- "Acceptance Criteria" -> read "## Verification Criteria"
- "Verification Steps" -> read "## Steps to Reproduce" (the steps that trigger the defect, used to confirm it no longer occurs)
- "Description" / feature goals -> read "## Expected Behavior"
The QA outcome section format and reporting rules are the same.

IMPORTANT — test location for defects:
Write all new tests for this defect under `tests/defects/defect-<id>/` (not alongside feature tests).
This namespaces defect tests so they can be reviewed and cleaned up after the fix is confirmed.
Existing tests in `tests/` must still be run for regression — do not move or modify them.
</If>

Read these files before starting:
- .mash/plan/architecture.md
- .mash/plan/project.md
- .mash/dev/<type>-<id>.md

<If branching: worktree — read ${CLAUDE_SKILL_DIR}/shared/worktree-context.md, use the QA template, substitute type and id, and append it here>"
)
```
After the agent returns, read the `---MASH_STATUS---` block in the agent output to get the status directly. If the block is absent, fall back to reading `.mash/dev/<type>-<id>.md`.

**After completing, return to the calling loop.**
