# BRANCH SETUP

Called with `<type>` (`feature` or `defect`) and `<id>`. Runs only if `branching: worktree` in settings.md; skip entirely if `branching: current_branch`.

- Check if `.mash/worktrees/<type>-<id>` already exists (stale from an interrupted run):
  - If both the directory and branch `mash/<type>-<id>` exist: skip creation and continue.
  - If only one exists (mismatched state): warn the user and use AskUserQuestion to ask how to proceed, offering:
    - *Recreate the missing element* — create the missing worktree or branch to restore consistent state, then continue.
    - *Proceed without the worktree* — treat this feature as `current_branch` for this run only.
    - *Abort* — stop so the user can manually resolve the inconsistency.
- Otherwise: create branch `mash/<type>-<id>` from the current branch, then create the worktree: `git worktree add .mash/worktrees/<type>-<id> mash/<type>-<id>`.

**After completing, return to the calling command.**
