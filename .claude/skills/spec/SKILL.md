---
name: spec
description: Turn an underspecified feature, bug or improvement into a code-grounded implementation specification with testable acceptance criteria. Use when asked to spec something out, clarify requirements, prepare an implementable ticket, or turn an idea into a concrete backlog item.
license: MIT
---

# Implementable specification

Read applicable repository instructions. Use the existing conversation rather than asking the user to repeat the request. This workflow defines work; it does not implement it, spawn another agent or publish an issue by default. Honor the host's Plan-mode rules and allowed output paths.

## Understand the need

Establish who is affected, current behavior, desired behavior, why it matters and how success will be observed. Separate known facts from assumptions. Ask only high-value missing questions, a few at a time; skip questions already answered by the request or code.

If the underlying problem or product direction is still uncertain, use the office-hours approach before specifying a solution. Do not force commercial startup questions onto internal tools or personal projects.

## Ground the scope

- Read relevant entry points, interfaces, schemas, tests and existing documentation before proposing technical changes.
- Cite actual paths and symbols for current behavior. Mark planned new files as proposed. For greenfield work, state what was searched and what has not yet been built.
- Define in-scope behavior, non-goals and dependencies. Include failure modes, authorization, compatibility and operational constraints where relevant.
- Resolve material architecture choices with options and a recommendation. Prefer robust, simple, maintainable designs over development-cost shortcuts.
- Use measurable requirements without inventing measurements. Mark unknown performance targets or external guarantees as open questions.

## Draft

Produce a specification sized to the task:

1. **Problem and goal:** users, motivation and observable outcome.
2. **Current state:** verified behavior, source references and relevant limitations.
3. **Scope:** included behavior and explicit non-goals.
4. **Proposed design:** affected components, contracts, state/data changes and key decisions. Include schemas or examples only when they remove ambiguity.
5. **Failure and compatibility behavior:** applicable retries, duplicates, permissions, migration and recovery.
6. **Acceptance criteria:** numbered, independently verifiable pass/fail statements.
7. **Verification:** representative end-user journeys and meaningful tests, including important negative cases. State infrastructure needs and what remains unverified.
8. **Delivery:** dependency order, rollout and rollback when applicable.
9. **Open questions:** unresolved decisions and assumptions, with their impact.

Do not impose arbitrary test counts, effort estimates or a large template on a small change. For bug specifications, separate a reproduced symptom from a confirmed root cause.

## Review and hand off

Present the draft for correction where requirements remain ambiguous. Keep a chat request in chat. Save to a requested file only when permitted, preserving existing content. File or update a GitHub/Linear issue only when requested; inspect the intended project and possible duplicates first and report the resulting URL.

An external reviewer, numeric quality score or particular issue tracker is not required. End with readiness and the decisions an implementer still needs. Do not automatically start implementation.
