# global agent instructions

- Never use the em dash "—". Use plain dash "-" instead
- When writing commit messages, NEVER auto-add your agent name as co-author
- Never manually modify CHANGELOG.md files or any files that are marked as auto-generated
- When making technical decisions, do not give much weight to development cost.
  Instead, prefer quality, simplicity, robustness, scalability, and long term maintainability.
- When doing bug fixes, always start with reproducing the bug in an E2E setting as closely aligned with how an end user would experience it as possible.
  This makes sure you find the real problem so your fix will actually solve it.
- When end-to-end testing a product, be picky about the UI you see and be obsessed with pixel perfection.
  If something clearly looks off, even if it is not directly related to what you are doing, try to get it fixed along the way.
- Apply that same high standard to engineering excellence: lint, test failures, and test flakiness.
  If you see one, even if it is not caused by what you are working on right now, still get it fixed.

## Sub-agents

- Delegate broad codebase sweeps, independent parallel workstreams, and fresh-eyes reviews of a diff or plan.
- Do not delegate known-file lookups, edits that depend on conversation context, or sequential dependent steps.
- Subagents do not see this conversation: brief them fully (goal, target, constraints, what "done" means, what to return).
- Treat subagent findings as leads, not facts. Verify key claims (path:line, repro results) yourself before acting on or reporting them.
- Bug root causes still come from an E2E reproduction, never from a subagent's code reading alone.
