# MASH: init

Initialize a new MASH project.

**Arguments**: optional `<filepath>` — a file to use as pre-seeded project description.

## Steps

1. **Bootstrap scaffolding if missing**: Check whether `.mash/plan/` exists. If not, create the project scaffolding now using Bash:
   ```bash
   mkdir -p .mash/plan/features .mash/dev
   touch .mash/plan/features/.gitkeep .mash/dev/.gitkeep
   ```

2. Read `skills/mash/references/init-persona.md` and **execute its instructions directly** in the current conversation. Do NOT spawn a sub-agent — init requires multi-turn interaction with the user via AskUserQuestion.

3. If the user provided a filepath argument (e.g. `mash init path/to/brief.md`), read that file before executing init-persona and pass its content as the pre-seeded project description. If the file cannot be read, warn the user and fall back to the standard init flow with no pre-seeding.

**After init-persona completes, stop.**
