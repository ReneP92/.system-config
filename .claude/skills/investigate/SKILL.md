---
name: investigate
description: Systematically debug errors, regressions, flaky behavior and unexpected results. Use when asked to fix a bug, investigate an error, explain why something broke, or find a root cause. Reproduce the end-user failure before changing implementation.
license: MIT
---

# Root-cause investigation

Read repository instructions and respect the requested scope. A diagnosis-only request or Plan/read-only mode permits investigation, not repairs. An investigation does not authorize commits or publication.

## 1. Reproduce the user's experience

Start with the failing browser journey, API request, CLI invocation or job execution as closely as the environment allows. Record expected and actual behavior, inputs, version, relevant configuration and error output. Read setup instructions as needed to run it. If the project has a verification skill (`.claude/skills/verify-*/`), use its launch, doctor, drive and evidence recipes and its feature map.

For jobs and webhooks, inspect the final durable state, not only acceptance. For a flaky failure, record the conditions and failure frequency under a bounded run. If reproduction is blocked, say why and collect the smallest missing evidence; do not label a guessed repair verified.

## 2. Trace the cause

- Follow the failure backward through callers, state transitions and external boundaries. Read full relevant functions and their tests.
- Compare working and failing cases, recent changes and environment differences. A recent change is a lead, not proof.
- At each boundary, determine what entered, what left and where observed behavior first diverged from the contract.
- When you reach the state that triggered the symptom, decide whether that state is legitimate. If it is, handle it where the code broke. If it should never exist, a check at the failure point hides the bug, so keep tracing back to what produced it. Guards, retries, swallowed errors, clamped values and defaults that discard state are the usual ways a bug gets hidden.
- Check similar paths for the same cause. Do not call two implementations duplicates before reading their different guards and callers.

## 3. Test hypotheses

State a specific claim: "Given X, Y produces Z because ..." Identify the observation that would disprove it. Change one variable at a time or use a focused probe; distinguish test/setup failures from the reported product bug.

For flakes, investigate races, order dependence, shared fixtures, timers and resource contention. Prefer condition-based synchronization or controlled clocks over sleeps and inflated timeouts.

When two attempts that share an assumption fail the same check, suspect the assumption, not the attempts. Pause edits and write the assumption down as one sentence. Before the next attempt, make an observation that would come out differently if the assumption were false, and look at which cases fail and which pass, not only how badly they fail. If the evidence contradicts the assumption, find what the failures share that it did not predict. After three failed attempts of any kind, pause edits and summarize what was disproved. Seek missing evidence or a decision rather than stacking speculative patches.

## 4. Repair when authorized

Make the smallest clear change that eliminates the confirmed cause. Ship only what the evidence justifies: a defensive change that "might help" is a hypothesis, not a fix, and when evidence refutes a hypothesis, revert the changes it motivated. Preserve user work and follow project conventions. Never manually change changelogs or generated files; use the documented generator when relevant.

Add or extend a meaningful regression test when warranted. Establish that it fails for the original defect and passes with the repair without destructively resetting the user's checkout. For a purely visual or reversible low-impact change, appropriate before/after runtime evidence may be enough.

## 5. Verify and report

Repeat the original end-user reproduction on the repaired code. Run affected tests and required lint/build checks, broadening to integration or the full suite when the blast radius warrants it. Investigate failures and flakes rather than weakening checks. Avoid rerunning unchanged successful checks without a reason.

Return the symptom, confirmed root cause or remaining hypothesis, changed paths, exact verification results and any remaining blocker. Distinguish fixed-and-verified, diagnosed-only, and unverified. Never substitute "should fix it" for observed evidence. If finding the deciding fact took a deep dig, propose the cheap, always-on signal (a log line, metric, assertion or clearer error message) that would have shown it at first look.
