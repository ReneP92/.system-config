---
name: ship
description: Validate completed work and prepare or publish its pull request using repository-native checks. Invoke explicitly to ship a branch, create a PR, or perform final delivery validation. Follows the project's release workflow and preserves unrelated user changes.
disable-model-invocation: true
license: MIT
---

# Validate and ship

Read repository instructions, release documentation and CI configuration. Respect the user's requested endpoint: validation-only, local commit, push or PR. In Plan/read-only mode, explain the required steps without committing, fetching, modifying or publishing. This skill does not authorize merging a PR, deploying, tagging or publishing a package unless the user explicitly requests that endpoint.

## 1. Establish delivery scope

- Inspect branch, status, intended base, remote and existing PR metadata. Determine the actual base rather than assuming `main` or `origin`.
- Identify which changes belong to this task, including untracked files. Preserve unrelated changes; do not stage everything, stash work or reset the checkout as a shortcut. Clarify ownership if task changes cannot be separated reliably.
- If a PR requires a feature branch and the current branch is the default branch, create or select an appropriate feature branch without losing work.
- Refresh remote information when permitted. Follow the repository's integration policy; do not automatically rebase, merge the base branch or force-push. Resolve a required integration before final verification.

## 2. Validate the actual candidate

1. Compare implementation against acceptance criteria and review the complete scoped diff, using `eng-review` when available. Read its `SKILL.md` through the host's skill facility or from the sibling skill directory. External-model reviews are optional, not prerequisites.
2. Discover checks from project manifests, scripts and CI. Run the relevant tests, lint, type checks and builds. Exercise changed user-facing behavior where practical, not just static checks.
3. Investigate failures or flakes; repair causes without weakening checks. Record unavailable prerequisites honestly. Unresolved required checks block publication rather than becoming a green result.
4. Audit documentation against changed behavior and update authored documentation when needed. Never manually edit `CHANGELOG.md` or any generated file. Use documented generation/release automation where applicable; do not invent a VERSION file, bump policy or changelog entry.
5. Inspect the final diff for accidental files, secret exposure, unrelated edits and whitespace errors. Rerun checks whose inputs changed after verification, including changes made during review or documentation work. Do not rerun unaffected successful checks needlessly.

## 3. Commit and publish to the requested endpoint

- Stage only verified task paths or hunks. Include meaningful tests with the behavior they protect.
- Use project commit conventions. Never auto-add the agent as a co-author. Do not create empty commits or rewrite existing commits without authorization.
- Before a push, confirm branch and remote. Use a normal push; investigate non-fast-forward failures instead of forcing them.
- Reuse an existing PR for the branch when present. Use the configured forge CLI or connector, and inspect existing title/body before updating them.
- Describe the actual change, checks run and remaining limitations. Link the relevant GitHub or Linear issue only when known; use a closing reference only if the work meets its acceptance criteria.
- If required tooling or authentication is missing, report the blocker and leave verified local work intact. Do not claim a push or PR succeeded without its tool result.

## Final result

State checks and their outcomes, what was committed/pushed, and the PR URL if created or updated. Distinguish local validation, PR publication, CI completion, merge and deployment. A PR URL is not evidence that CI passed or that production was deployed.
