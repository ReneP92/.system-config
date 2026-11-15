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
- For frontend, UI or UX work, load the `frontend-craft` skill.
- Apply that same high standard to engineering excellence: lint, test failures, and test flakiness.
  If you see one, even if it is not caused by what you are working on right now, still get it fixed.

## Sub-agents

- Delegate broad codebase sweeps, independent parallel workstreams, and fresh-eyes reviews of a plan. Code reviews go to a new session instead (see Code reviews).
- Do not delegate known-file lookups, edits that depend on conversation context, or sequential dependent steps.
- Subagents do not see this conversation: brief them fully (goal, target, constraints, what "done" means, what to return).
- Treat subagent findings as leads, not facts. Verify key claims (path:line, repro results) yourself before acting on or reporting them.
- Bug root causes still come from an E2E reproduction, never from a subagent's code reading alone.

## Code reviews

- Always run a code review in a new session, never in the session that wrote the code. A subagent of the authoring session does not count.
- Brief the new session fully, because it sees none of this conversation: the goal of the change, the target (branch, base and range, or paths), the constraints that matter, and the name of the original session to report back to.
- In Claude Code, get this session's name from `ListAgents` and start the reviewer with `claude --bg -n review-<topic> "<brief>"`. Tell it to run `/eng-review` and post its findings to the original session with `SendMessage`.
- The review session posts its findings to the original session rather than only leaving them in its own transcript. If it cannot reach the original session, it says so in its final output and keeps the findings there.
- The original session treats the findings as leads: confirm each one, fix the confirmed ones, and report which ones were dropped and why.
