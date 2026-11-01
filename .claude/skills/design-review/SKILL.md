---
name: design-review
description: Audit visual and interaction quality of an implemented web interface. Use for design polish, visual QA, inconsistent spacing or typography, responsive layout problems, accessibility and interaction-state reviews. Supports fixes when requested, with before/after evidence.
license: MIT
---

# Visual and interaction review

Read repository instructions, existing design guidance, tokens and shared components. Identify the requested page or journey; use changed UI paths when a diff is the target. Preserve the product's visual language. Review by default; repair when asked to polish/fix or when `--fix` is supplied. `--report-only` and Plan/read-only modes prohibit edits.

## Capture the baseline

Open the actual interface with available browser tools and record viewport, route and state. Inspect a representative desktop and narrow viewport plus important loading, empty, error, disabled, focused and populated states. Use screenshots for visible defects and console/network evidence for interaction failures.

If the interface cannot run or browser access is unavailable, report that limitation. Source inspection or a supplied screenshot can support a limited review, not a claim that live interactions and responsive layouts were tested.

## Audit

- **Hierarchy:** clear purpose, primary action, grouping, reading order and appropriate information density.
- **Typography:** consistent scale, weights, line height, line length, wrapping and text truncation.
- **Layout:** spacing rhythm, alignment, consistent gutters, container width, overflow and responsive transitions.
- **Components:** consistent controls, icons, borders, radii, surfaces and token usage; reuse existing components where their behavior fits.
- **Accessibility:** labels, keyboard operation, visible focus, contrast, semantics and reduced-motion behavior. Automated scans supplement manual checks rather than proving full accessibility.
- **Interactions:** understandable state changes, validation, feedback, touch targets, recovery and absence of accidental layout shifts.
- **Visual specificity:** identify decorative clutter or inconsistent styling with concrete evidence. Do not replace the project's identity with generic gradients, cards or a fashionable redesign.

Prioritize by user impact and visibility. Describe the actual mismatch rather than giving arbitrary design scores. Be precise about small defects: a repeated alignment or spacing error can materially harm polish.

## Fix and recheck when authorized

Trace the rendered element to authored source. Prefer fixing a shared component or token when the defect is genuinely shared, and inspect its other consumers. Never hand-edit generated stylesheets or changelogs. Avoid unrelated redesigns.

Reopen the same route, viewport and state after each coherent repair. Compare before/after screenshots and recheck keyboard and responsive behavior. Use functional regression tests where behavior changed; pure visual fixes may be verified with browser evidence. A CSS edit alone is not proof of visual improvement.

Do not commit or publish automatically. Return prioritized findings, changes if any, before/after evidence, checked viewports/states and remaining coverage gaps. Stop speculative repairs if the interface cannot be reverified.
