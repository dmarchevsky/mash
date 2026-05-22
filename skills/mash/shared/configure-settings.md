# CONFIGURE SETTINGS

Shared procedure — called from the `config` command and from init-persona Phase 1. Works whether or not `.mash/plan/settings.md` already exists.

1. **Read current state:**
   - If `.mash/plan/settings.md` exists: read it and extract `git`, `branching`, and `commit` values. This is an **update run**.
   - If not: this is a **first-time run** — no current values exist.
   - Read permissions: if `.claude/settings.local.json` exists, extract `permissions.allow` (treat as `[]` if absent); if `opencode.json` exists at the project root, extract `permission` (treat as `{}` if absent). If both exist, read both. If neither exists, treat as empty.

2. **If update run** — display current configuration:
   ```
   ## Current MASH Configuration

   Git branching:  <branching value>
   Git commit:     <commit value>

   Sub-agent permissions (.claude/settings.local.json):   <- only if file exists
     Bash(*)      <present / MISSING>
     Edit(/**)    <present / MISSING>
     Write(/**)   <present / MISSING>

   Sub-agent permissions (opencode.json):                 <- only if file exists
     bash         <present / MISSING>
     edit         <present / MISSING>
     webfetch     <present / MISSING>
   ```
   Show only the section(s) for config files that actually exist. If neither exists, show "No permission config file found."

3. **Ask what to configure** using AskUserQuestion with multiSelect enabled:
   - `Git branching` — choose `worktree` or `current_branch` *(omit if `git: none`)*
   - `Git commit` — choose `auto` or `manual` *(omit if `git: none`)*
   - `Sub-agent permissions` — set or update permissions in applicable config file(s)
   - `Nothing — just viewing` *(update run only)*

4. **Handle each selected item:**

   #### Git branching
   Ask the user to choose with AskUserQuestion:
   - `worktree` — create a per-feature branch and git worktree. Keeps the current branch clean. **Requires `commit: auto`** (MASH must handle merge-back).
   - `current_branch` — work directly on the current branch. Simpler but mixes feature work.
   If the user selects `worktree` and `commit` is currently `manual`, automatically set `commit: auto` and inform the user: *"Switched commit mode to auto — worktrees require automated merge-back."*
   Write or update the `branching:` line in `.mash/plan/settings.md`.

   #### Git commit
   Ask the user to choose with AskUserQuestion:
   - `auto` — MASH commits and merges after each feature/defect passes QA.
   - `manual` — MASH leaves changes uncommitted. The user handles commits and merges.
   If choosing `auto`, note that sub-agents will run git commands autonomously (`git commit`, `git merge`, `git checkout`) — covered by `Bash(*)`.
   **Constraint**: If `branching: worktree` is set, `commit` must be `auto`. Worktrees require automated merge-back — manual commit with worktrees leaves the user with a complex multi-step git cleanup. If the user selects `manual` while `branching: worktree`, inform them of this constraint and offer: switch branching to `current_branch`, or keep `commit: auto`.
   Write or update the `commit:` line in `.mash/plan/settings.md`.

   #### Sub-agent permissions
   Check required permissions per config file: for `.claude/settings.local.json` check `Bash(*)`, `Edit(/**)`, `Write(/**)` ; for `opencode.json` check `bash`, `edit`, `webfetch`. If `commit: auto` is set, mention that this includes autonomous git operations.
   - If all are already present in every applicable config: report "All required permissions are already configured."
   - If any are missing: show which ones (per file) and use AskUserQuestion to ask whether to add them.
   - If approved: write missing permissions to each applicable config file, merging into the existing structure and preserving any other entries. If both files exist, write to both. If neither exists: check whether `.opencode/` directory is present — if so, create `opencode.json`; otherwise create `.claude/settings.local.json`.
   - If declined: warn that sub-agents will prompt for each action.

5. **Display final configuration** (same format as step 2).

**After completing, return to the calling command.**
