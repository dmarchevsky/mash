# FAILURE CLASSIFICATION

Used by failure handling in both the implementation loop and patch loop.

- **Implementation bug**: the approach is sound but the code has specific, fixable errors (wrong logic, missing import, off-by-one, etc.). -> Propose targeted changes and retry.
- **Approach failure**: the approach was executed correctly but did not achieve the goal — code ran, tests passed technically, but the real-world outcome was not achieved. -> Do NOT retry the same approach. Use AskUserQuestion to ask the user what alternative approach to try, or whether to discuss why this approach is failing. Only proceed after the user proposes a different approach. Record what was tried and why it didn't work in the spec's Technical Notes (features) or Debugging Notes (defects) so future attempts don't repeat it.
