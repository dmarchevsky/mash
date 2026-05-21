# WORKTREE CONTEXT TEMPLATES

Substitute `<type>` (feature/defect) and `<id>` at invocation time.

## WORKTREE CONTEXT (impl)

Used by dev-persona and patch-persona. Append to the agent prompt:

```
---
WORKTREE CONTEXT:
This <type> is being developed in an isolated git worktree.
- worktree_path: .mash/worktrees/<type>-<id>
- All source code exploration and modification must use this path (e.g., .mash/worktrees/<type>-<id>/src/ instead of src/)
- The <type> file (.mash/dev/<type>-<id>.md) and .mash/plan/ files remain in the main project directory — access them there as normal
- Do NOT read or modify src/ in the main project directory
```

## WORKTREE CONTEXT (qa)

Used by qa-persona. Append to the agent prompt:

```
---
WORKTREE CONTEXT:
This <type> was implemented in an isolated git worktree.
- worktree_path: .mash/worktrees/<type>-<id>
- All source code inspection and test execution must use this path (e.g., .mash/worktrees/<type>-<id>/src/)
- Write tests to the test directory within the worktree, using the path defined in architecture.md (e.g. if architecture.md specifies `tests/`, write to `.mash/worktrees/<type>-<id>/tests/`) [for defects: to `tests/defects/defect-<id>/` within the worktree]
- The <type> file (.mash/dev/<type>-<id>.md) and .mash/plan/ files remain in the main project directory — access them there as normal
- Do NOT read or test src/ in the main project directory
```
