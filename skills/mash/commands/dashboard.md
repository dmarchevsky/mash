# MASH: dashboard

> **Path note**: `.mash/` paths below are in the user's project directory (CWD), not in this framework's install directory.

Show project status and suggest next steps.

1. **Check init status**: Check if `.mash/plan/project.md` and `.mash/plan/architecture.md` exist and have content beyond templates.
2. **If not initialized**: Report that the project hasn't been set up yet, then suggest:
   - `/mash init` — set up your project (define goals, architecture, git workflow)
3. **If initialized**: Read `.mash/plan/progress.md` and display a status summary:
   - Total features, how many are DONE, WIP, DEV_READY, CREATED, FAILED
   - List features with their current status (compact table or list). For features showing `WIP`, also read `.mash/dev/feature-<id>.md` and show the dev file status in parentheses (e.g. `WIP (DEV_DONE)`). If the dev file doesn't exist yet, show `WIP` only.
   - Then suggest relevant next commands based on the state:
     - If there are CREATED features not yet planned in detail: `/mash plan` — refine and add feature specs
     - If there are DEV_READY or WIP features: `/mash dev` — implement all pending features, or `/mash dev <ids>` — implement specific features
     - If all features are DONE: `/mash plan` — plan new features, or `/mash fix` — log and fix a defect
     - If there are FAILED features: mention them and suggest reviewing the failure details
   - Also always show:
     - `/mash status` — refresh this status view
     - `/mash config` — view or change git settings and sub-agent permissions
     - `/mash update` — check for framework updates
4. **Defect summary**: Scan `.mash/dev/defect-*.md` for any files with status other than `QA_PASS`. If any exist, show a count of open defects and suggest:
   - `/mash fix <id>` — resume an in-progress defect
   - `/mash fix` — log and fix a new defect

**After displaying the dashboard, stop.** Do not proceed to any other steps.
