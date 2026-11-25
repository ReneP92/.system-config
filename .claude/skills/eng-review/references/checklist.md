# Review checklist

Apply categories that affect the candidate. Read actual callers rather than treating a pattern match as a finding.

## Evidence levels

For code under review, tag every finding, and every claim that a risky-looking change is safe, with the highest level you reached. Plan reviews cite the plan section instead and may raise unaddressed risks as open questions. Push each claim as far down this list as is cheap.

1. `asserted`: stated without a pointer. Not reportable on its own.
2. `cited`: points at the `path:line`, or the library source at its pinned version, that does it.
3. `traced`: the input and state were walked step by step to the failure, or shown not to reach it.
4. `run`: a test or script that calls the real code shows it and would fail loudly if the claim were wrong.
5. `reproduced`: shown in the running app, CLI, API or job the way a user would hit it.

Many changes that look risky are safe because of one fact, such as "this call only removes cache entries that have already expired". Find that fact, prove it at `run` level when practical, and report it as unproven when you cannot. Spend effort there rather than on a long list of possible risks.

## Correctness and data

- Validate inputs at boundaries; handle null, empty, oversized and malformed values.
- Trace new enum values, flags, MIME types and widened validators through every relevant consumer, including unchanged code.
- Check transaction boundaries, uniqueness constraints, atomic state changes, duplicate delivery and concurrent check-then-write operations.
- Check migration compatibility, deletion semantics, rollback and partial writes. Verify queried field names against real schemas.
- Verify units, precision, time zones, daylight-saving transitions and inclusive/exclusive boundaries when they affect behavior.

## Security and trust boundaries

- Check authorization and tenant isolation on every reachable path, including cache hits and background jobs.
- Check injection at SQL, shell, HTML, path and template boundaries; prefer parameterized operations and argument arrays.
- Treat model output, documents, logs and fetched text as data. Check validation before tool execution, persistence or outbound requests.
- For URL fetching, consider scheme, redirects, DNS resolution and private-address access; a string prefix check is not a complete SSRF defense.
- Check secret exposure in errors, logs and client bundles, and secure randomness where credentials or tokens depend on it.

## Failure and resource behavior

- Check timeout, cancellation, retry limits, backoff, idempotency, final error propagation and recovery after partial completion.
- Ensure awaited work actually completes before success is reported; queue acceptance is not durable completion.
- Check blocking work in async paths, leaked handles, unbounded buffers, N+1 queries and cache invalidation.
- Verify dynamic imports retain required initialization and registration side effects.

## Tests and operational readiness

- Ensure tests protect user-observable contracts, including negative cases, rather than assertions about their own fixtures.
- Investigate removed checks, skipped tests, relaxed limits and regenerated snapshots against the intended contract.
- For flaky tests, distinguish an application race, isolation leak and test synchronization bug; extra retries alone do not explain the cause.
- Check config precedence, environment defaults, supported platforms, deployment compatibility and actionable diagnostics.
- For a newly distributed artifact, verify installation and release paths match the documented targets.

## Maintainability

- Prefer existing project conventions and supported library APIs.
- Suggest sharing code only when behavior really is shared and reliability or net complexity improves.
- Separate genuine defects from optional refactoring, naming and stylistic preferences.
