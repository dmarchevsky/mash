# POST-FEATURE

Runs after a feature reaches ARCH_VERIFIED (QA_PASS + architect confirmation).

1. Read `skills/mash/shared/extract-lessons.md` and follow its instructions for this feature.

2. Read `git`, `commit`, and `branching` from `.mash/plan/settings.md` and act accordingly:

**If `git: none`:**
- Mark feature as DONE in progress.md. Inform the user that feature <id> passed QA and changes are ready (no git in use).

**If `commit: auto`:**
- Commit the changes for this feature with a descriptive message (run `git commit` from within the worktree if `branching: worktree`, or from the project root if `branching: current_branch`).
- If `branching: worktree`:
  - Merge the feature branch (`mash/feature-<id>`) back into the original branch.
  - If the merge produces conflicts: stop and inform the user with the conflicting files listed — do NOT run WORKTREE CLEANUP. Ask the user to resolve conflicts on the original branch, then confirm to proceed with cleanup.
  - On successful merge: run WORKTREE CLEANUP for this feature.

**If `commit: manual`:**
- Do NOT commit or merge. Inform the user that feature <id> passed QA and changes are ready.
- If `branching: worktree`, inform the user which worktree/branch contains the changes and leave it in place.

### WORKTREE CLEANUP

Skip entirely if `git: none` in settings.md.

If `branching: worktree` in settings.md and a worktree exists for the item:
1. `git worktree remove .mash/worktrees/<type>-<id>` (use `--force` if needed).
2. `git branch -d mash/<type>-<id>` (only if the branch has been merged; use `-D` if FAILED status and user confirms).

**After completing, return to the implementation loop.**
