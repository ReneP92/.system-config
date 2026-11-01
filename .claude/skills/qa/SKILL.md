---
name: qa
description: Exercise real application behavior across browsers, APIs, CLIs, background jobs and webhooks. Use when asked to run QA, test a feature end to end, find functional bugs, or test and fix an application. Select the relevant surface rather than assuming every product has a webpage.
license: MIT
---

# Functional QA

Read repository instructions and identify the target, environment and intended behavior from the request, current plan or relevant diff. Clarify an ambiguous target. Respect Plan/read-only restrictions, including restrictions on test commands that create files or mutate state.

Default to testing and reporting. Apply repairs when the user requests fixes or passes `--fix`; `--report-only` explicitly keeps the run diagnostic. Do not commit, stash, reset or publish as part of QA. A dirty working tree can be the intended test candidate: record and preserve it.

## Prepare

1. Inspect documented setup and existing test tooling. Use available browser automation, HTTP clients, shell tools and native runners; do not assume gstack binaries or a particular framework.
2. Choose a representative happy path, important boundary and failure cases, and adjacent behavior affected by the change. Read `references/surfaces.md` for the selected surfaces.
3. Use isolated test data and a local or designated test environment for mutating probes. Identify where durable effects land. If access or tooling is missing, report the blocked surface and continue independent checks.
4. Save screenshots or logs only to permitted locations when useful; avoid overwriting earlier evidence. Record the command/request, relevant input, expected outcome and actual result. Exclude credentials from reports.

## Exercise the contracts

- Follow the real entry point, including authentication and setup that affect behavior. Do not replace the journey with a unit test and call it E2E coverage.
- Test failure recovery as well as the happy path: invalid input, unavailable dependencies, duplicates, cancellation and retries where applicable.
- Observe final state and side effects, including their absence on failure. A successful exit or HTTP status alone may not establish the intended result.
- Inspect visual quality during browser testing: spacing, alignment, overflow, typography, responsive behavior and interaction states. Include clearly visible defects in findings.
- Keep a scenario ledger: passed, failed, blocked, not run. A skipped test or unreachable environment never becomes a pass.

## Repair loop, when requested

For each reproducible defect, capture baseline evidence, trace the root cause, repair responsible code and rerun the exact failing journey plus adjacent behavior. Use the investigation workflow for uncertain causes. Add a meaningful regression test where warranted, favoring existing test infrastructure over a new framework.

Do not manually modify generated files or changelogs. Do not remove assertions, suppress errors or increase retries simply to make checks green. After repeated unsuccessful repairs, stop speculative edits and report the unresolved cause. Preserve unrelated work and any useful failing reproduction.

## Finish

Return a compact scenario table with outcome and evidence, then prioritized defects with reproduction steps and expected/actual behavior. Mark each repair verified or unverified and list missing coverage. Cite screenshot/log paths when created. A code read, mocked test and live journey provide different evidence: label each accurately.
