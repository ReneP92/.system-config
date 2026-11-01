---
name: test-audit
description: Audit an existing test suite for weak assertions, duplicate coverage, flaky tests and test-only complexity. Use when asked to assess test value, identify redundant tests, improve an aging suite, or plan test cleanup. Report findings before removing or rewriting tests.
license: MIT
---

# Test-value audit

Read repository instructions and identify the requested suite or subsystem. Default to discovery and recommendations. Change only a specifically authorized cleanup batch, and never in Plan/read-only mode. Optimize for confidence in real behavior, not deleted lines or fewer tests.

## Inventory

Inspect test-runner configuration, CI lanes, fixtures, nearby production code and relevant failure history. Determine what can actually run. State the surveyed scope; use representative owners or modules for a large suite rather than claiming exhaustive coverage from a grep.

Use searches as leads for:
- Tests that assert source text or implementation details rather than a user-visible contract.
- Assertions that only repeat fixture setup, cannot fail for the claimed defect, or never observe the relevant result.
- Duplicate scenarios with no distinct boundary, platform, integration or failure-mode coverage.
- Excessive mocks that bypass the behavior a test claims to verify.
- Sleeps, order dependence, shared-state leakage, skipped tests and unexplained retry/timeout increases.
- Production exports or switches that appear to exist only to support tests.

A matching pattern is not proof of low value. Source checks can enforce a legitimate static contract; snapshots and mocks can protect meaningful behavior. Read the owner and consumers before classifying.

## Build an evidence card

For each candidate, record:

1. Test path/name and the behavior it is intended to protect.
2. The concrete regression that would make it fail, or evidence that it cannot detect the claimed regression.
3. What it does not prove because of mocks, fixtures or an unobserved boundary.
4. Proposed action: keep, strengthen, consolidate, repair flakiness or remove.
5. Remaining coverage: exact surviving tests and their relevant assertions, or a replacement needed before deletion.
6. Evidence from execution or a bounded mutation/probe where useful and permitted, with limitations.

Never remove a test solely because coverage percentages remain unchanged or a similar test name exists. If unique protection cannot be ruled out, keep or strengthen it. Do not remove production APIs based only on absent repository references; external consumers may exist.

## Recommend and apply

Present a small prioritized batch with evidence and rationale. Obtain authorization for that batch before editing; a request to audit is not authorization to delete. Do not invent numeric savings or flake rates.

For an authorized batch, preserve the behavior it protects and remove test-only scaffolding only when its ownership and lack of consumers are established. Do not manually edit changelogs or generated files. Run the owner tests, affected sibling/integration checks and required lint/type/build checks. Do not edit files while a test runner is using them.

Report what was retained, strengthened, consolidated or removed, actual verification results and remaining gaps. Leave commits and publication to a requested shipping workflow. Finding no worthwhile cleanup candidates is a valid outcome.
