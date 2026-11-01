---
name: investigate
description: Systematically debug errors, regressions, flaky behavior and unexpected results. Use when asked to fix a bug, investigate an error, explain why something broke, or find a root cause. Reproduce the end-user failure before changing implementation.
license: MIT
---

# Root-cause investigation

Read repository instructions and respect the requested scope. A diagnosis-only request or Plan/read-only mode permits investigation, not repairs. An investigation does not authorize commits or publication.

## 1. Reproduce the user's experience

Start with the failing browser journey, API request, CLI invocation or job execution as closely as the environment allows. Record expected and actual behavior, inputs, version, relevant configuration and error output. Read setup instructions as needed to run it.

For jobs and webhooks, inspect the final durable state, not only acceptance. For a flaky failure, record the conditions and failure frequency under a bounded run. If reproduction is blocked, say why and collect the smallest missing evidence; do not label a guessed repair verified.

## 2. Trace the cause

- Follow the failure backward through callers, state transitions and external boundaries. Read full relevant functions and their tests.
- Compare working and failing cases, recent changes and environment differences. A recent change is a lead, not proof.
- At each boundary, determine what entered, what left and where observed behavior first diverged from the contract.
- Check similar paths for the same cause. Do not call two implementations duplicates before reading their different guards and callers.

## 3. Test hypotheses

State a specific claim: "Given X, Y produces Z because ..." Identify the observation that would disprove it. Change one variable at a time or use a focused probe; distinguish test/setup failures from the reported product bug.

For flakes, investigate races, order dependence, shared fixtures, timers and resource contention. Prefer condition-based synchronization or controlled clocks over sleeps and inflated timeouts.

After three failed repair attempts, pause edits, summarize what was disproved and reconsider the underlying model. Seek missing evidence or a decision rather than stacking speculative patches.

## 4. Repair when authorized

Make the smallest clear change that eliminates the confirmed cause. Preserve user work and follow project conventions. Never manually change changelogs or generated files; use the documented generator when relevant.

Add or extend a meaningful regression test when warranted. Establish that it fails for the original defect and passes with the repair without destructively resetting the user's checkout. For a purely visual or reversible low-impact change, appropriate before/after runtime evidence may be enough.

## 5. Verify and report

Repeat the original end-user reproduction on the repaired code. Run affected tests and required lint/build checks, broadening to integration or the full suite when the blast radius warrants it. Investigate failures and flakes rather than weakening checks. Avoid rerunning unchanged successful checks without a reason.

Return the symptom, confirmed root cause or remaining hypothesis, changed paths, exact verification results and any remaining blocker. Distinguish fixed-and-verified, diagnosed-only, and unverified. Never substitute "should fix it" for observed evidence.
