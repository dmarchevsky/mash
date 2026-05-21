# Status Reference

## Status Transitions

**progress.md:** CREATED -> DEV_READY -> WIP -> DONE | FAILED

**dev/feature-\<id\>.md:** DEV_READY -> WIP -> DEV_DONE -> QA_PASS -> *(ARCH_VERIFIED = DONE)* | DEV_FAIL | QA_FAIL

**defect-\<id\>.md:** DEV_READY -> WIP -> PATCH_DONE -> DEV_DONE -> QA_PASS | PATCH_FAIL | QA_FAIL

**Architect codes:** ARCH_APPROVED (pre-dev: spec OK, proceed) | ARCH_FAIL (conflicts/gaps, user decides) | ARCH_VERIFIED (post-qa: coverage confirmed, set DONE)

**Status sync (dev -> progress.md):**
| Dev status | progress.md |
|-----------|-------------|
| DEV_READY / WIP / DEV_DONE / DEV_FAIL / QA_FAIL | WIP |
| QA_PASS | WIP (awaiting architect) |
| ARCH_VERIFIED | DONE |
| attempt > 3 | FAILED |

**MASH_STATUS block fields by persona:**
| Persona | Key field | Values |
|---------|-----------|--------|
| dev-persona | `status`, `blocker`, `verified_steps` | DEV_DONE / DEV_FAIL |
| qa-persona | `status`, `blocker`, `tests_passed` | QA_PASS / QA_FAIL |
| architect-persona (pre-dev) | `result`, `conflicts` | ARCH_APPROVED / ARCH_FAIL |
| architect-persona (post-qa) | `result`, `gaps` | ARCH_VERIFIED / ARCH_FAIL |
| patch-persona | `status`, `blocker` | PATCH_DONE / PATCH_FAIL |

## Concepts

### Outcome-based feature
A feature whose goal is a verifiable real-world result — not that the code runs, but that a specific observable outcome was achieved. Examples: data was retrieved from a live external API, a user successfully authenticated, a connection to a live service was established. For these features, "tool ran and returned output" is **not** success — the content of the result must prove the goal was actually achieved. A Cloudflare challenge page is not a bypass. An empty dataset is not a successful retrieval. Always ask: does the output prove the goal, or merely that the goal was attempted?

## Safety Rules

- **Never write code in `src/` or `tests/` yourself.** Always delegate to sub-agents via the Agent tool.
- **Halt at 3 failed attempts.** Set progress.md to FAILED and report to the user.
- **Feature files are the contract.** Dev and QA agents read them; you manage and update them.
- **Always update status** in both progress.md and dev feature files after state changes.
- **Commit after ARCH_VERIFIED.** Create a git commit for each successfully completed feature — only after the architect confirms goal coverage.
- **Ask before large plans.** If a `plan` command would create more than 5 features, show the plan and ask for confirmation before creating files.
- **Always use AskUserQuestion.** When you need user input — choices, confirmations, or clarifications — use the AskUserQuestion tool. Never just print a question as text.
- **Defect files are the contract for patching.** Never invoke patch-persona without a defect file that includes a Fix Recommendation confirmed by the user.
