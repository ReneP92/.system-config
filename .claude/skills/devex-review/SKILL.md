---
name: devex-review
description: Test the developer experience of a CLI, SDK, API or developer tool. Use for a DX audit, trying onboarding, evaluating CLI help and errors, validating getting-started documentation, or checking installation and upgrade friction.
license: MIT
---

# Developer experience audit

Read applicable instructions and identify the intended developer, product surface and supported environment. Actually follow the documented experience where possible. Review by default; edit only when fixes are requested. Respect Plan/read-only mode, including installation and test side effects.

## Follow the first-use journey

1. Read the public getting-started instructions as a new user would. Identify prerequisites and the first meaningful result.
2. Use an isolated temporary project, home or environment when practical so existing credentials, caches and global dependencies do not hide setup defects. Do not alter the user's shell configuration to make the example work.
3. Run the documented steps, recording commands, output, detours and failures. Measure time to first successful result only if the journey was actually run; state what setup was pre-existing and what was excluded.
4. Confirm the promised outcome, not just a successful install or build. If blocked by authentication or unavailable infrastructure, report the exact boundary.

## Exercise the interface

- **CLI:** discoverability of commands, help, naming, defaults, exit codes, stdin, stdout/stderr separation, non-TTY behavior, machine-readable output, paths with spaces and cancellation.
- **SDK:** minimal runnable example, imports/types, consistent method names, lifecycle/cleanup, async behavior, errors, pagination and version compatibility.
- **API:** authentication setup, request/response contracts, error shape, retries, idempotency, pagination and useful examples.
- **Configuration:** precedence, validation, overrides, local/CI parity and understandable diagnostics for missing or invalid settings.

Trigger representative failures deliberately in the isolated environment: bad arguments, missing config, invalid input or unavailable dependencies. An actionable error should identify the operation, cause and next step without exposing secrets. Check that automated consumers get stable exit codes and usable structured output where promised.

## Check the lifecycle

Verify that documented examples match the installed version. Inspect navigation, conceptual explanations, reference coverage and troubleshooting. Test upgrade, compatibility and removal paths where relevant and feasible without disturbing user state. Compare actual results against prior plans or claimed setup times, labeling inference separately.

If repairs are requested, reproduce the friction first, fix authored code/docs and repeat the affected journey. Do not manually edit changelogs or generated docs; use the project's generator when relevant. Do not commit or publish automatically.

## Report

Give a concise table: journey/dimension, observed outcome, evidence, impact, recommendation. Mark evidence as tested, partially tested, source-inferred or blocked. Include actual onboarding timing only when measured. Prioritize friction that prevents the first success, misleading errors and broken automation contracts over subjective naming preferences.
