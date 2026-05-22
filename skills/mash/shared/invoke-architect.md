# INVOKE ARCHITECT

Two modes: **pre-dev** and **post-qa**. Called with `mode`, `trigger_file`, and optional context flags.

---

## Pre-dev mode

Runs after setting progress.md to WIP and before INVOKE DEV. Checks that the feature spec is consistent with the project architecture before implementation begins.

**If this is a reimplementation** (flag set during reimplementation setup): before invoking, read all existing `## Dev outcome (attempt N)` and `## QA outcome (attempt N)` sections from the trigger file. Append a REIMPLEMENTATION CONTEXT block to the prompt:
```
---
REIMPLEMENTATION CONTEXT:
The user has requested reimplementation of a previously completed feature.
The Dev outcome (attempt N) section(s) in the feature file document what was built before.
Review these outcomes alongside the feature spec and consider:
- Whether the prior approach had limitations or left acceptance criteria partially addressed
- Alternative approaches that may better satisfy the goals
- What, if anything, should be preserved from the prior implementation
Include a concrete approach direction in your report for the dev agent to follow.
```

Read `${CLAUDE_SKILL_DIR}/references/architect-persona.md` and invoke the Agent tool with both required parameters (`description` and `prompt`):
```
Agent(
  description="MASH Architect pre-dev",
  prompt="<architect-persona.md contents>

---
PARAMETERS:
- mode: pre-dev
- trigger_file: <trigger_file path>

Read these files before starting:
- .mash/plan/architecture.md
- .mash/plan/project.md
- <trigger_file path>

<If REIMPLEMENTATION CONTEXT — append it here>"
)
```

After the agent returns, read the `---MASH_STATUS---` block in the agent output (`result` field). If the block is absent, scan the report text for `ARCH_APPROVED` or `ARCH_FAIL`.
- **If ARCH_APPROVED**: if `extensions_documented > 0`, display a one-line notice: *"Architect documented <N> extension(s) to `architecture.md` (see report above)."* Then proceed to INVOKE DEV.
- **If ARCH_FAIL**: present the specific CONFLICT items (including each item's proposed architecture.md edit) to the user via AskUserQuestion with four options:
  - *Proceed to dev anyway* — implement as spec'd; architect concerns noted but not blocking.
  - *Update feature spec now* — pause the loop, allow the user to direct changes to the feature file, copy updates to the dev file, then re-run pre-dev architect before proceeding.
  - *Update architecture.md* — apply the architect's proposed edit(s) to `.mash/plan/architecture.md`, then re-run pre-dev architect. If re-run returns ARCH_APPROVED, proceed to dev. If ARCH_FAIL again, present options again for remaining conflicts.
  - *Skip this feature* — set status to FAILED in progress.md and move to the next feature.

---

## Post-qa mode

Runs after QA_PASS for both features and defects. Invoked by MASH — not a sub-agent of QA. Verifies that QA evidence covers all stated goals and acceptance criteria, not just that tests passed.

Read `${CLAUDE_SKILL_DIR}/references/architect-persona.md` and invoke the Agent tool with both required parameters (`description` and `prompt`):
```
Agent(
  description="MASH Architect post-qa",
  prompt="<architect-persona.md contents>

---
PARAMETERS:
- mode: post-qa
- trigger_file: <trigger_file path>

Read these files before starting:
- .mash/plan/architecture.md
- .mash/plan/project.md
- <trigger_file path>

"
)
```

After the agent returns, read the `---MASH_STATUS---` block in the agent output (`result` field). If the block is absent, scan the report text for `ARCH_VERIFIED` or `ARCH_FAIL`.
- **If ARCH_VERIFIED**: mark the feature or defect as DONE in progress.md, then proceed normally (POST-FEATURE for features; user confirmation step for defects).
- **If ARCH_FAIL**: present the specific coverage gaps to the user via AskUserQuestion with three options:
  - *Send back to QA with architect notes* — set file status to DEV_DONE, append the architect's gap list as a `## Architect notes` section in the dev/defect file, then re-invoke QA with the note: *"IMPORTANT: The architect identified coverage gaps (see Architect notes section). QA must address each gap before setting QA_PASS."* Then go back to the QA phase.
  - *Accept and proceed* — note the gaps in the progress report and proceed to POST-FEATURE / user confirmation.
  - *Return to dev* — if the gaps reveal an implementation problem rather than a QA gap, set file status to DEV_READY and return to the implementation/patch loop.

**After completing, return to the calling loop.**
