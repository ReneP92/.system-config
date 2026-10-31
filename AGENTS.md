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

## gstack

- Use the installed `gstack-*` skills for gstack workflows. In OpenCode, prefer the native OpenCode versions over Claude compatibility copies.
- OpenCode skill IDs are directory names: when a gstack command requests a short name such as `review`, load `gstack-review` instead. Keep IDs already prefixed with `gstack-` unchanged.
- Use `/gstack-browse` for web browsing. Never use `mcp__claude-in-chrome__*` tools.
