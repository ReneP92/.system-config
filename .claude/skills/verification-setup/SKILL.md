---
name: verification-setup
description: Create or maintain a project-local verification skill that launches the real app, drives it the way a user does and captures evidence, with a feature map of user-facing features. Use for /verification-setup, when a project has no scripted way to prove UI, CLI, API or job behavior, or to audit an existing verify skill against the current app.
disable-model-invocation: true
license: MIT
---

# Verification setup

Every project worth verifying needs a scripted way to drive the real app: launch it, exercise a feature as a user would, and capture evidence. This skill generates that as a project-local skill, `.claude/skills/verify-<app>/`, and keeps it honest as the app changes. `investigate` and `qa` use it when it exists, so each run reuses a tested recipe instead of working out from scratch how to start and drive the app.

Write the generated skill for the next agent, not for a human. It will be read cold, mid-task, by an agent that has never seen the app.

## Scope and authorization

- Write only inside the verification skill's directory, plus verification scaffolding marked as such. Any other change (product code, configuration, dependencies, lockfiles) needs the user's approval.
- If `.claude/skills/verify-<app>/` already exists, extend it: add what is missing and correct what is proven wrong. Never overwrite an existing file wholesale, and say which files you changed.
- Never commit or publish; leave that to a requested shipping workflow. In Plan or read-only mode, report what the skill would contain.
- The generated skill may belong in a shared repository or only in the user's checkout. Say that it is untracked and let the user decide (`.git/info/exclude` keeps it local).

Mode: **maintain** when the user says so or a `verify-*` skill with a feature map already exists. Otherwise **create**.

## Create

### 1. Interview the repository, not the user

Answer these from the code. Ask the user only what you cannot observe.

- **Surface:** what a user touches: web UI, desktop app, CLI or TUI, API, job or webhook, mobile app, library. Pick the primary one and note the others.
- **Run:** how the app starts locally, starting from the repository's documented dev command. Note ports, environment variables, seed data and authentication.
- **Drive:** how an agent can interact with it from a script. Existing harnesses first (Playwright or Cypress setups, expect scripts, PTY helpers, HTTP endpoints, a debug port). Then a generic recipe: a browser automation library or the Chrome DevTools Protocol for web and Electron, a tmux or PTY session for CLI and TUI, plain HTTP for services.
- **Observe:** what evidence can be captured: screenshots, accessibility snapshots, terminal transcripts, response bodies, logs, exit codes, database state.
- **Isolate:** where the app keeps data, configuration, profiles and accounts, and how to point each at a run-scoped location: environment overrides, `HOME` or `XDG_*` variables, a `--user-data-dir` flag, a throwaway database or container. A documented dev command often reads the developer's `.env`, their own database, or a per-user directory such as `~/.config/<app>`; never assume it is isolated. Also note whether a second launch hands off to an already running instance, as single-instance desktop apps do.

If the checkout does not build or start as-is, report the failure precisely and stop. A skill written against a broken base teaches wrong steps. The one exception: when an irrelevant missing asset blocks startup, the generated skill may create it, marked as verification scaffolding, and remove it in cleanup.

### 2. Generate the skill

Write `.claude/skills/verify-<app>/SKILL.md`. Its frontmatter has `name: verify-<app>` and a `description` that names the app and its surface and says to use it for launching, driving and verifying the app; without frontmatter the skill never registers. Every section is grounded in what the interview found, with no placeholders left:

- **Launch:** the exact command that starts the app for verification, with data, configuration, profile and accounts pointed at run-scoped locations, and a free port chosen per run (or a check that fails when the port is taken). Record the process group of what it starts. Say how to tell the app is ready: usable, not just answering, since a database health check can pass while its init scripts still run. Launch must reach a usable state from an empty data directory, including migrations and seed data. For a short-lived CLI or TUI, launch means building or installing once, then running each drive in its own isolated session.
- **Doctor:** one read-only check that answers "is this instance worth driving?": process up, expected build or revision, port owned by this run, authentication valid, and data, configuration and profile locations equal to this run's scoped ones. Doctor fails on any mismatch. Run it before the first drive and whenever something looks off.
- **Real-data fallback:** if run-scoped isolation is impossible, the generated skill says so, and every journey that mutates state stops before acting and asks the user. Never drive an instance the run did not start.
- **Drive:** the harness recipe with real selectors and commands from this repository. Prefer stable handles (accessible roles and names, data attributes, prompt strings, route paths) over coordinates and tab order.
- **Evidence:** what to capture and where it goes, as a named directory outside the repository unless the project keeps such artifacts. Proof exercises the real user path, not internal setters or test-only endpoints. Capture the action and the resulting state, not only the final screen. Verify side effects (files written, rows inserted, messages sent) alongside what is visible. Use mocks only where a production boundary already isolates the external system. When the safe path is a dry run or test mode, observe what it actually skips (files, network, git refs) rather than trusting its name. Keep secrets out of evidence: never echo credential variables, and redact tokens and auth headers from transcripts, logs and response bodies.
- **Cleanup:** stop the process group recorded at launch and remove run-scoped data and scratch state. Never kill by process name or by port. Cleanup never removes evidence; confirm it still exists afterwards.
- **Helpers:** when driving takes more than a few literal commands, ship a small executable script in the skill's `scripts/` directory with subcommands such as `launch`, `doctor`, `drive`, `capture` and `cleanup`. Show each invocation in the skill body as a path from the repository root (`.claude/skills/verify-<app>/scripts/<script>`). Build it on the repository's own test tooling where possible. A script is the recipe; a host's built-in browser or computer-use tools are not, because other hosts and future sessions may not have them.

Never write credentials into the skill. Name the environment variables or secret store they come from.

### 3. Seed the feature map

Create `features/README.md` and one file per user-facing feature, starting with the top three to five from routes, commands, menus or docs. Follow the shape in [`references/feature-map-example.md`](references/feature-map-example.md). Each feature file says, from the user's point of view, what the feature is, how to reach it, how to drive it with the harness and what observable end state proves it works.

If the seed data lacks a precondition a journey needs, the journey reports a failure and the reason goes in that feature's Gotchas. Never weaken a journey to make it pass. A proof that drives one convenient entry point is incomplete when the map lists others.

### 4. Prove the generated skill

Follow its instructions end to end once: launch, doctor, drive one mapped feature, capture evidence, clean up. After cleanup, confirm the evidence still exists where the skill says. Fix what fails, and run the generated cleanup after every failed attempt so broken attempts do not strand processes and ports. A generated skill that was never executed is a draft, not a deliverable.

If you proved it in a stand-in for the real target (a container instead of a fresh machine, a local stack instead of a remote one), list every step the stand-in did that the real target will not. Those stay unverified.

## Maintain

A feature map goes stale as soon as the app changes. The unit of coverage is the feature: cover every feature file from source and exercise every feature live.

Edit only the verification skill's directory. Never edit product code during a maintain pass. Behavior the map describes that the app no longer has is either drift (fix the map) or a product regression (report it, never paper over it in the map).

1. **Locate the target.** The project-local `verify-*` skill with launch and drive sections and a feature map. If there are several, ask which one. If there is none, switch to create mode.
2. **Index.** Read `features/README.md` and list its sibling files. Fix missing, extra, duplicate or dead entries.
3. **Source pass.** For each feature file, explain from source how the feature works now, cite likely drift, and write one live recipe. For more than a few features, run this as read-only subagents in parallel, one per feature; they never drive the app or edit files.
4. **Reconcile.** Merge recipes into as few app states as practical. Spot-check cited drift. Look through recent changes for user-facing features missing from the map, and require a concrete source path before calling one missing.
5. **Live pass.** Required even when the source looks clean. You drive, serially, following the skill's own launch model. Exercise every feature at least once. Throughout the pass:
   - Run doctor before the first drive, on each fresh session, and after any failed drive. Where doctor cannot see the failure (a stuck UI on a healthy process), reset or relaunch.
   - Evidence captured so far survives every cleanup; check it at its location.
   - Clean up whatever a failed drive left behind before the next drive.

   A doctor failure caused by drift in the skill is drift: fix it and retry once before calling the pass blocked. A feature counts as unreachable only with the concrete missing prerequisite (authentication, entitlement, operating system, external state) and the route attempted.
6. **Triage.** A wrong or missing user-facing description is drift: fix it. Working behavior the harness cannot drive is a harness gap: fix it, and re-drive the fix live. Broken app behavior is a product defect: report it.
7. **Teardown.** After the last drive, including re-drives of harness fixes, run the skill's cleanup so nothing the pass started outlives it, then confirm the evidence still exists.

## Report

Create: the generated or extended paths, the surface and harness chosen, how runs are isolated from real data (or that they are not, and which journeys therefore ask first), the features seeded, the proof run's commands with their results and evidence location, steps that remain unverified, and a note that the skill is untracked.

Maintain: the outcome (clean, changed or blocked, with what blocked it), features covered live, unreachable features with their prerequisites, drift fixed, harness gaps fixed and product defects found. Leave committing the corrections to the user or `/ship`.
