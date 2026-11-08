---
name: plan-eng-review
description: Review a technical plan or architecture before implementation. Use when asked to review system design, challenge an implementation plan, assess technical tradeoffs, or identify failure modes and test gaps before coding.
license: MIT
---

# Engineering plan review

Review the plan in the conversation or the target the user names. If several targets are plausible, ask which one. Read applicable repository instructions and relevant code before judging proposed changes. Keep this a review: do not implement features, exit Plan mode, or create plan/report files unless requested and permitted by the host.

## Establish the problem

1. State the goal, target and important constraints in a few lines. Separate observed behavior, proposed behavior and assumptions.
2. Trace the existing entry points, interfaces, storage and tests the plan would touch. Check whether a built-in, dependency or existing component already solves the problem.
3. Challenge unnecessary scope and accidental complexity. Prefer quality, simplicity, robustness, scalability and long-term maintainability over development-cost estimates. Similar-looking code alone does not justify an abstraction.
4. If the host offers a `fresh-eyes-reviewer` subagent, start it now so it reviews in parallel with you, unless the plan is a single small change confined to one component with no interface, data or security impact. It cannot see this conversation, so brief it with the full plan text, the goal, the constraints and the code areas involved. Treat its findings as leads: confirm each against the plan and code before reporting it, and drop the ones you cannot confirm. If you skip it, say why in the report.

## Review four dimensions

### Architecture and data flow

- Map component responsibilities, trust boundaries and ownership of state. Use a small diagram when it clarifies the flow.
- Trace one successful request and relevant failures through the entire system, including asynchronous completion.
- Check authentication, authorization, tenancy, consistency, concurrency, retries, idempotency, cancellation and partial failure where applicable.
- For migrations or interface changes, assess mixed-version operation, rollout, rollback, data compatibility and observability.

### Implementation quality

- Verify proposed interfaces against actual callers and installed dependency versions.
- Prefer explicit control flow, clear error contracts and the simplest robust design.
- Identify hidden coupling, duplicated business rules, ambiguous ownership and assumptions that cannot yet be supported.
- Distinguish requirements from optional cleanup. A speculative risk is a question, not an observed defect.

### Tests and verification

- Map each important behavior and failure mode to an observable check. Include empty, malformed, duplicate, unauthorized and boundary inputs as relevant.
- Start bug-fix verification with an end-user reproduction. Choose the lowest useful test layer plus the necessary integration or E2E evidence.
- Specify what regression each proposed test catches. Avoid source-text assertions, tests that merely repeat implementation, and unnecessary tests for reversible low-impact changes.
- State what mocks, unavailable infrastructure and missing fixtures leave unverified.

### Performance and operations

- Assess query count, indexing, hot paths, resource bounds, backpressure, caching and invalidation against the expected workload.
- Define measurements for uncertain performance claims; do not invent latency or scale numbers.
- Check diagnostics, failure recovery and distribution for newly published packages or tools.

## Resolve and report

For material decisions, give the evidence, options, tradeoffs and a recommendation. Ask only about choices that cannot be resolved from the request or repository. Carry prior answers forward; do not repeatedly ask for the same decision.

Return:
- Readiness: ready, ready with named open questions, or blocked.
- Prioritized findings with plan sections or source paths and a concrete recommendation.
- A compact verification matrix: behavior, failure case, check, expected result.
- Decisions made and unresolved assumptions, including rollout or rollback concerns.

Keep the review proportional to the change. State when no actionable issues were found. Hand off to implementation only when the user requests it and the active mode permits it.
