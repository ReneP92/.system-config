---
name: correct
description: Make a mistake that agents keep repeating impossible instead of adding another instruction. Use when the user corrects the same kind of mistake a second time, asks to stop agents from repeating a mistake, or invokes /correct. Fixes each mistake class at the highest level that works, from architecture down to docs, and proves each new check fails on a real past mistake.
license: MIT
---

# Make repeated mistakes impossible

The user keeps correcting agents for the same mistakes. Change the repository, or the user's agent setup, so the next agent cannot make them. An instruction is the weakest fix: nothing fails when an agent skips it.

Assume every contributor is an agent that sees only the files it opened, copies the nearest example and takes the shortest path that compiles. A change that looks right from one file should be right for the whole repository.

Read repository instructions and respect the requested scope.

## Scope and authorization

- **Loaded by the agent after a repeated correction.** Fix the mistake the user just corrected, then propose the enforcement for that one class: the level, the destination and the change. Make the enforcing change only after the user approves it. Do not sweep history for other classes.
- **Invoked as `/correct` or explicitly requested.** Run the full workflow below. That authorizes working-tree changes in the current repository for the classes you confirm. Changes to the user's global agent setup still need the user's approval for each class.
- Neither mode authorizes commits or publication; leave those to a requested shipping workflow. In Plan or read-only mode, report the classes and the proposed enforcement without editing.

## Where the fix goes

- **Code and project conventions** (an API to use, a pattern to avoid, a test to keep) go in the current repository, and its rule table goes in that repository's agent instruction file.
- **Agent behavior and personal preferences** (writing style, commit trailers, forbidden commands, how to report) go in the user's global agent setup: their global instructions file and host hooks, such as `~/.claude/CLAUDE.md` and `~/.claude/settings.json`. If those are symlinks, edit the file they point to. Keep that rule table in the global instructions file. Never write a personal preference into a project repository's instructions or CI.

## 1. Find the mistake classes

Collect evidence of corrections, not guesses about what might go wrong:

- The user's corrections in the current session and, when the host keeps them, recent session transcripts for this project (Claude Code stores them under `~/.claude/projects/`).
- Recent commits, reverts and fix-up commits, and review comments on recent PRs.
- Agent instruction files (AGENTS.md, CLAUDE.md, rules files): a rule written there is a mistake that already happened.
- Code comments that explain a workaround or warn against an approach.

Group the evidence into classes. A class counts once it has happened twice. Record each occurrence with its source (commit, PR comment, transcript date) so the class is traceable.

## 2. Fix each class at the highest level that works

Try the levels in this order and stop at the first one that makes the mistake fail or impossible:

1. **Architecture.** Give each piece of state one owner and each task one supported way to do it. Hide internals so the wrong import fails. Replace hand-synced lists with one source of truth. Delete old ways and dead code an agent would copy.
2. **Types.** Make the bad state unrepresentable, so the wrong code does not compile.
3. **A lint, CI check or agent hook.** When the bad code still compiles, add a check whose error names the file, type or function to use instead. For mistakes in agent behavior rather than code (writing style, forbidden commands, commit trailers), a host hook such as a Claude Code `PreToolUse` or `Stop` hook is the equivalent. If the pattern is already common, fail only when a change adds more occurrences.
4. **A test.** Assert the behavior the mistake broke. Fix or delete any existing test that still passes when that behavior breaks, or that fails when only the internals change.
5. **An instruction, last.** Use it only for judgment calls no check can decide. Make it specific, put it where the agent reads it at the moment of the decision, and include an example of the failure.

When a level above the one you chose was possible but not taken, say why.

## 3. Prove each check

For each new check, show it fails on a real past occurrence of the mistake: run it against the commit, file or output that contained it, and paste the failure. Get old file versions with `git show <rev>:<path>` into a temporary file, or a separate `git worktree`; never check out, stash or reset the user's working tree. Then show it passes on the corrected code. A check that has never failed is unproven.

Run the same command locally that CI runs. An exception goes on the offending line with a reason and an owner, never as a blanket disable.

## 4. Keep the rule table

Keep a table in the agent instruction file for that destination (see "Where the fix goes"), creating it with the first enforced rule, that pairs each rule with what enforces it (a type, a lint rule name, a hook, a test, or "judgment"). When the user corrects you again:

- Fix the mistake.
- If the rule was missing, add it and enforce it at the highest level that works.
- If the rule was already there and nothing enforces it, that is a repeat. Enforce it in the same change.
- Remove a rule once its mistake can no longer happen.

## Report

For each class: the evidence (occurrences with sources), the level chosen and why no higher level worked, the change made, and the proof that the check fails on a real past mistake. List classes you found but did not fix, and why. Say "no repeated classes found" when the evidence does not reach two occurrences.
