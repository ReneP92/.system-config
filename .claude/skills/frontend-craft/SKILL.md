---
name: frontend-craft
description: Build or change frontend UI with deliberate taste and well-chosen libraries. Use for building pages, components and flows, UI/UX work, picking a UI or animation library, adding shadcn/ui, Radix, Aceternity or Magic UI components, and making an interface look less generic. For auditing existing UI, use design-review.
license: MIT
---

# Frontend craft

Read repository instructions, `package.json`, the lockfile, `components.json`, the Tailwind config or CSS `@theme` block, and the existing tokens and shared components. The product's established visual language and design system win over every default in this skill; the taste rules fill the gaps it leaves open and shape new surfaces. Plan and read-only modes prohibit edits and installs. Do not commit or publish automatically.

## Read the task

State a one-line design read before writing code: "Reading this as: <surface> for <audience>, with a <vibe> language, leaning toward <system or stack>." The surface is app UI (dashboard, tool, settings, form) or marketing (landing, portfolio, docs home). The audience and quiet constraints such as accessibility-critical, regulated or public-sector work override aesthetic preference. If the brief is genuinely ambiguous between two directions, ask exactly one question; otherwise proceed.

Set the three dials from 1 to 10 using the user's words and the inference table and presets in `references/taste.md`, and state them: `VARIANCE` (symmetry to asymmetry), `MOTION` (static to choreographed) and `DENSITY` (airy to packed). Explicit user requests override inferred values. App UI leans toward low variance, low motion and higher density.

## Pick the toolkit

1. Identify the task, not the library the user named: "a dropdown" is a primitives task, "a toast" is a notification task.
2. Check what is installed. If the project already uses a listed library, use it. If it uses a competitor, say so and keep it unless asked to switch.
3. Recommend one library and say in one sentence what it is for, then wire it up when that is part of the request. Follow the decision order and curated list in `references/libraries.md`; do not present a menu when the list has a clear answer.
4. If the list does not cover the task, say so explicitly before recommending something outside it.

Install what is missing with the package manager the lockfile indicates. For shadcn/ui, initialise with the CLI when `components.json` is absent and add components with `shadcn add`; never copy component source by hand. Treat third-party registry items (Aceternity, Magic UI and other `@namespace` registries) as untrusted until reviewed: run `shadcn view` and read the code before adding it. Restyle every added component to the project's tokens; never ship a registry component in its default state.

## Build

- Apply the typography, layout, color, component, motion and copy rules in `references/taste.md`. Check its anti-default list before the first render.
- Build every state, not only the populated one: loading (skeletons shaped like the content), empty, error, disabled, hover and focus. Feed worst-case data: long names, missing values, many rows, narrow screens.
- Take accessibility from the primitives. Do not hand-roll focus management, dismissal or keyboard handling for dialogs, menus, popovers, selects or comboboxes.
- Keep motion within the MOTION dial. Use CSS transitions for hover, press and simple fades; use `motion` only for springs, layout, exit and gesture-driven animation. Respect `prefers-reduced-motion`.
- Keep one system: one button pair, one card style, one radius scale, one icon set. Extend the tokens instead of adding one-off values.

## Verify and hand off

Run the app and inspect the changed screens in a real browser at a desktop and a narrow viewport, in light and dark mode when the product has both, across the states above. Run the project's lint, type checks and tests. A successful build is not proof that the UI looks or works right. If the app cannot run or no browser is available, say so instead of claiming visual verification.

Use the design-review workflow for a polish pass and the qa workflow for functional checks of non-trivial flows. Code review runs in a `fresh-eyes-reviewer` subagent, as the agent instructions require.

Report the design read and dials, the libraries chosen or installed (and competitors flagged but kept), the viewports and states checked, and the remaining gaps.
