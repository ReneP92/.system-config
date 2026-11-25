---
name: no-comments
description: Clean up the comments in a diff before review. Deletes narration, commented-out code and stale notes, flags comments that excuse surprising code for a reshape, offers checks for "do not remove" constraints, and audits lint and type suppressions. Keeps only comments that carry what the code cannot. Invoke explicitly with /no-comments.
disable-model-invocation: true
license: MIT
---

# Comment cleanup

A comment is either something the code cannot say, or a sign the code should say it better. Keep the first kind, reshape the code behind the second, and delete the rest.

Read repository instructions and respect the requested scope.

## Authorization

- Invoking this skill authorizes, inside the scope: deleting comments, correcting or shortening kept comments, adding a missing reason to a suppression, and trivial reshapes (renaming a local, extracting a constant).
- Everything else is a proposal until the user approves it: non-trivial reshapes, workaround root-cause fixes, enforcement for constraints, other suppression changes and code fixes behind suppressions.
- `--report-only` and Plan or read-only modes allow classification only.
- Never commit or publish; leave that to a requested shipping workflow.

## Scope

Use the files or diff the user names. Otherwise use the branch diff from its merge base with the base branch, through the working tree, including non-ignored untracked files (`git ls-files --others --exclude-standard`).

- In a diff, classify every comment the diff adds or changes, every comment in untracked files, and existing comments on or inside the symbols the diff changes (including their doc comments) that the change made wrong.
- With named files, classify every comment in them.
- Never touch generated files, vendored code or changelogs. Never edit outside the scope, even to fix the same pattern. Report stale comments found elsewhere instead.

## Classify

Give every comment in scope exactly one verdict. Check the classes in this order and take the first that fits: Constraint (for comments with constraint wording), then Keep, then Workaround and Suppress, then Reshape, then Delete. When you are unsure whether a keep item applies, keep the comment and report it as uncertain.

**Keep** only these:

1. Legal and license headers.
2. Comments a tool reads. This includes tests that live in comments (Go `// Output:` example blocks, Python doctests, Rust doc tests), docstrings used as CLI help or `__doc__`, shebangs, encoding lines, build tags and `go:generate`, cgo preambles, bundler annotations (`/*#__PURE__*/`, magic comments), Dockerfile `# syntax=` lines, test-environment annotations, formatter pragmas, type annotations in comments and generated-file markers. Suppressions are judged under Suppress below.
3. Doc comments on the public API: anything exported from the package's public surface, a CLI, or a config schema, whether or not this repository calls it.
4. Behavior forced by something we cannot change: a dependency bug, a platform or vendor quirk, a protocol or spec requirement. Prefer a link to the issue, RFC or doc.
5. A "why" the code cannot carry: a tradeoff, a rejected alternative or a non-obvious invariant, where no rename, type or extracted function would express it. It must be true for the current code.
6. A TODO or FIXME with an owner or an issue link.

A kept comment that is wrong or longer than it needs to be gets corrected or shortened, never padded. Shortening never drops an issue link, an owner or a removal condition ("remove after Node 18").

**Constraint:** "do not remove", "must run before X", "keep in sync with Y", "IMPORTANT". Warning words earn no protection on their own. Verify the claim against the current code and the commit that added the comment (`git log -S`, `git blame`).

- Refuted: the named in-repository thing no longer exists or no longer behaves that way. Delete the comment.
- True and enforceable: propose the cheapest enforcement in scope (a type, an assertion, a test or a lint, or one source of truth for "keep in sync"). Keep the comment until the approved enforcement lands, then delete it.
- True but not enforceable: keep it as keep item 4 or 5.
- Unverifiable, including any claim about stored data, external systems or other repositories that nothing in the repository refutes: keep it and report it as unverified.

**Workaround:** "hack", "temporary", "fine for now", "this shouldn't be needed but". Find the root cause and propose the fix with the workaround's removal when it is small and in scope. Otherwise keep the comment, shortened to what the workaround is for, and report the root cause as open work. Never add a symptom guard.

**Suppress:** `eslint-disable`, `@ts-ignore`, `@ts-expect-error`, `# noqa`, `# type: ignore`, `//nolint`, `# shellcheck disable`, `#[allow(...)]` and similar. Look up the rule.

- A style-only or pedantic rule: keep the suppression. If it has no reason, add one in the tool's documented reason syntax (for example `-- reason` for ESLint, a separate `# reason` after a shellcheck directive); a reason in the wrong place can break the directive.
- A rule that catches real bugs or protects correctness or safety: the suppression hides a defect. Propose the code fix with the symbol and the rule.
- `@ts-ignore` where `@ts-expect-error` would work: propose the switch, so the suppression fails once it is no longer needed. Check every tsconfig that includes the file first, because the error may not occur under all of them.

**Reshape:** a comment that explains surprising behavior in our own code. The code should make the behavior obvious instead. Name the exact symbol and the reshape: rename, extract a function or constant, introduce a type, or restructure. Apply a trivial, local reshape; propose the rest. Once the reshape lands, delete the comment.

**Delete:**

- Narration of what the next lines do, and comments that restate a name or type.
- Commented-out code. Version control keeps it.
- Banners, dividers and section headers.
- History notes ("added X for Y", "changed to use the new API"). That belongs in the commit message. A note that links an external bug is keep item 4.
- A TODO or FIXME with no owner or issue link. List it in the report as open work so it is not lost.

## Steps

1. Establish the scope and list every comment in it with `path:line`.
2. If the host offers a `fresh-eyes-reviewer` subagent, have it classify the comments. The author of a change is attached to its comments, so the independent pass decides by default. Brief it with:
   - Goal: "Classify these comments per the Classify section of `~/.claude/skills/no-comments/SKILL.md`. This task replaces your findings format and the eng-review checklist. Do not edit."
   - Target: the step 1 list of `path:line` entries, and the base and range or paths for context.
   - Return: one row for every listed comment, Keep verdicts included: `path:line`, verdict, action, and the evidence for any Keep, Constraint or uncertain verdict.

   Without a subagent, classify the comments yourself.
3. Check the verdicts. Overturn a verdict only when it breaks a rule above: a keep item marked for deletion, a constraint called refuted without evidence, a reshape of code outside the scope, a keep that matches no keep item, or a verdict on a comment that is not in the step 1 list. Say which verdicts you overturned and why.
4. Apply the authorized edits, unless reporting only.
5. Run the lint, type check, tests and doc build that cover the touched files, and the formatter in check mode. Compare against a run before the edits:
   - A drop in the number of tests run is a regression, even when everything passes, because a deleted comment may have been a test.
   - When a deletion breaks a check, restore the comment and classify it again. Never add a suppression or placeholder code to make the check pass.
   - Format only the lines you edited; never reformat whole files.
6. Present the proposals. Apply each one only after the user approves it, then delete the comment it replaces.

## Report

The number of comments deleted, kept and corrected, with `path:line` for each kept comment and the keep item it matched. Then the reshapes applied and proposed, constraint verdicts with their evidence, uncertain and unverified keeps, suppression findings, overturned verdicts, open work (bare TODOs, out-of-scope root causes, stale comments outside the scope), and the checks you ran with their results, including the test counts before and after.
