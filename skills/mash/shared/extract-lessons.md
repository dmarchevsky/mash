# EXTRACT LESSONS

Called after a feature or defect completes successfully (after ARCH_VERIFIED). MASH performs this step itself — it is a meta-analysis task (reading outcomes and summarizing), not code writing.

1. Read all `## Dev outcome (attempt N)`, `## QA outcome (attempt N)`, and `## Patch outcome (attempt N)` sections from the completed dev/defect file.
2. Review the trajectory and ask these four questions:
   - Did an approach fail that seemed like it should work? -> **failure** lesson
   - Did we discover a project-specific constraint the hard way? -> **pitfall** lesson
   - Did a non-obvious approach succeed? -> **success** lesson
   - Did QA catch something that dev should have caught? -> **verification** lesson
3. **Boundary check**: If a potential lesson is really a convention or pattern that should govern future code structure (naming, dependency choice, module organization), it belongs in `architecture.md` — the architect already handles this. Only write to `lessons.md` if it is operational experience (failed approaches, tool/environment pitfalls, debugging discoveries, QA gaps).
4. **Skip extraction if**: attempt == 1 AND no QA failures AND no architect extensions — a clean first-attempt success does not produce lessons.
5. If lessons are identified: read `.mash/plan/lessons.md`, determine the next `L-NNN` ID from the highest existing entry, and append 1-3 lessons to the appropriate category section. Each lesson uses this format:
   ```
   ### L-NNN: <concise title>
   - **Source**: feature-<id> / defect-<id>
   - **Type**: success | failure | pitfall
   - **Context**: <one line: what was being built/fixed>
   - **Lesson**: <1-2 sentences: what worked, what didn't, or what to do differently>
   - **Tags**: <comma-separated keywords>
   ```

**After completing, return to the calling command.**
