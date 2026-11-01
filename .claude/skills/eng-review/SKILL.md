---
name: eng-review
description: Review code, a PR, or a working-tree diff for correctness, security, regressions and production readiness. Use for code review, checking a diff, or pre-merge review. This is the shared engineering review skill, named eng-review to avoid built-in review command collisions.
license: MIT
---

# Evidence-based code review

Read applicable repository instructions. Review by default; apply fixes only when requested, including an explicit `--fix`. `--report-only` and host Plan/read-only modes prohibit repairs. Never commit, push or publish a review merely because this skill was invoked.

## Establish the candidate

1. Identify the requested PR, commit range, paths or working-tree changes. Inspect branch, status and relevant diff. Do not assume a branch named `main` or an `origin` remote.
2. For a branch review, determine the intended base and merge base from repository/PR metadata. Report a stale or unavailable remote base rather than treating a failed fetch as an empty diff. Do not fetch in a mode that forbids writes to Git metadata.
3. Include relevant staged, unstaged and non-ignored untracked source when reviewing work in progress. Being on the default branch does not mean there is nothing to review. Preserve user changes.
4. Read the complete selected diff, then affected callers, contracts and tests. If the candidate is too large to cover, report the covered paths and remainder instead of claiming a complete review.

## Review

Read `references/checklist.md` and apply the relevant categories. Prioritize a demonstrable failing behavior, production failure, data loss or security boundary violation over stylistic preferences.

For each suspected finding:
- Trace the input and state needed to reach it. Check whether surrounding code or another part of the diff already prevents it.
- Inspect sibling entry points and consumers for the same defect class, especially newly accepted values or changed defaults.
- Prove the issue with a bounded test or end-user reproduction when practical and permitted. Distinguish observed failures from code-supported risks.
- Cite the smallest useful `path:line` range, the triggering condition, impact and a concrete fix direction.
- Inspect changed tests, snapshots, lint rules, timeouts and CI checks. A relaxation is not automatically wrong; establish whether it hides a regression or follows a legitimate changed contract.

Use Critical for severe exposure or data loss, High for major broken behavior, Medium for material narrower failures, and Low for minor defects. State reachability and uncertainty rather than manufacturing confidence scores. Keep optional simplifications clearly advisory.

## If fixing is requested

Reproduce first, then make a root-cause repair consistent with repository patterns. Do not manually edit changelogs or generated files. Do not silence failures by deleting assertions, raising timeouts or changing snapshots without establishing the correct behavior. Run relevant checks and inspect the final diff, including newly introduced regressions. No mandatory second model or subagent is needed.

## Output

Lead with findings in severity order:

`[High] path:line - Trigger and incorrect behavior. Impact. Recommended repair.`

Then state verified checks, unresolved findings, fixes if authorized, and coverage limits. If nothing actionable was found, say so and name the scope. Missing tools or unrun tests are missing evidence, not passing checks. Do not present this review as a comprehensive security audit.
