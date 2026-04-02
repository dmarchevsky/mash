---
id: <feature-id>
title: <short title>
---

# <title>

## Description
<!-- What to build -->

## Acceptance Criteria
<!-- Verifications used by QA after development to confirm completeness and release readiness -->
- <criterion 1>
- <criterion 2>

## Verification Steps
<!-- Concrete commands that prove the feature works. Requirements:
     - Must run through the application's user-facing entry point (CLI, API call, file output) — not through internal imports or test harness.
     - Must check actual output content, not just exit codes.
     - Must include at least one representative end-to-end user scenario.
     - Each step must be runnable in a fresh environment with no prior state unless setup is explicitly listed.
     Bad: `python -c "from app import search; assert search('x') is not None"` (internal import, no output check)
     Good: `python main.py search "test query"` → output contains at least one result with title and URL
     Run by dev after implementation (including end-to-end app check); verified again by QA. -->
1. **Run**: `<command>`
   **Expect**: <exact output, exit code, or observable behavior>

## Regression tests
<!-- Verifications run by QA after every new feature to ensure existing functionality isn't broken -->
- <regression test 1>
- <regression test 2>

## Technical Notes
<!-- Implementation hints, constraints, references -->

## Dev outcome (attempt 1)
<!-- Filled by dev-persona after implementation attempt. On retry, a new numbered section is appended. -->

## QA outcome (attempt 1)
<!-- Filled by qa-persona after verification. On retry, a new numbered section is appended. -->
