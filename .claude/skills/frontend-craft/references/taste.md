# Taste rules

Adapted from taste-skill (see `../NOTICE.txt`). These rules shape new surfaces and fill gaps in an existing design system; they never override a system the product already has. A user's explicit request beats any rule here.

## Dials

Each dial runs from 1 to 10. Every layout, motion and density decision below is gated by them.

**VARIANCE** (layout symmetry)
- 1-3: symmetric 12-column grid, centred content, equal padding.
- 4-7: offsets and overlap, mixed image aspect ratios, left-aligned headings over centred data.
- 8-10: asymmetric grids (`2fr 1fr 1fr`), masonry, large deliberate empty zones.
- From 4 up, collapse to a single column under 768px. Nothing may scroll horizontally.

**MOTION** (animation intensity)
- 1-3: no automatic animation; hover and press states only.
- 4-7: CSS transitions on transform and opacity, short cascades on load.
- 8-10: choreographed scroll and layout animation with `motion` or scroll-driven CSS. Never `window.addEventListener('scroll')` or scroll position in React state.

**DENSITY** (information per screen)
- 1-3: airy, large section gaps, few elements per view.
- 4-7: normal app spacing.
- 8-10: compact padding, no card boxes, 1px dividers, monospaced or `tabular-nums` figures.

**Inference** from the user's words:

| Signal | VARIANCE | MOTION | DENSITY |
| --- | --- | --- | --- |
| minimalist, clean, calm, editorial, Linear-style | 5-6 | 3-4 | 2-3 |
| premium consumer, Apple-like, luxury, brand | 7-8 | 5-7 | 3-4 |
| playful, experimental, agency, Awwwards | 9-10 | 8-10 | 3-4 |
| landing page, portfolio, marketing site | 7-9 | 6-8 | 3-5 |
| trust-first, public sector, regulated, accessibility-critical | 3-4 | 2-3 | 4-5 |
| redesign that preserves | match existing | existing +1 | match existing |
| redesign that overhauls | existing +2 | existing +2 | match existing |

**Presets:**

| Use case | VARIANCE | MOTION | DENSITY |
| --- | --- | --- | --- |
| App UI: dashboard, admin, internal tool | 3 | 3 | 7 |
| App UI: settings, forms, onboarding | 3 | 3 | 5 |
| SaaS landing | 7 | 6 | 4 |
| Agency or creative landing | 9 | 8 | 3 |
| Developer portfolio | 6 | 5 | 4 |
| Editorial or blog | 6 | 4 | 3 |
| Public-sector service | 3 | 2 | 5 |

## Anti-defaults

These are the statistical defaults that make UI look machine-made. Do not reach for them without a reason from the design read:

- Purple or blue "AI" gradients, neon glows, gradient text on large headings.
- A centred hero over a dark mesh background (banned outright when VARIANCE is above 4).
- A row of three equal feature cards.
- Glassmorphism everywhere; infinite micro-animations on everything.
- Inter with slate-900 as the whole identity.
- An unmodified shadcn/ui theme.

## Typography

- One family, or one display face plus one text face. Never three. Mono only for code and figures.
- Do not pick Inter, Roboto, Open Sans, Lato, Montserrat or Poppins as the default for new work; consider Geist, Satoshi, Outfit or Cabinet Grotesk, or a face that fits the brand. Keep whatever the project already uses.
- No serif faces in app UI; serif belongs to editorial and brand surfaces.
- Each heading level is at least 1.3 times the next. Tighten tracking on large headings (about -0.02em); the first heading should lead through weight and color, not sheer size.
- Body text 16px or larger, line height 1.5 to 1.7, lines capped near 65ch. Nothing under 13px.
- Use `tabular-nums` for figures that change or align in columns.
- Sentence case everywhere. No tracked all-caps labels.

## Spacing and layout

- Use a 4/8-based scale (4, 8, 12, 16, 24, 32, 48, 64, 96, 128) and consistent gutters. No arbitrary one-off values.
- Keep left and right content edges equal and aligned across sections.
- Use CSS Grid for structure instead of flex percentage math such as `calc(33% - 1rem)`.
- Use `min-h-[100dvh]`, never `h-screen`, for full-height sections.
- Use cards only when elevation communicates hierarchy; otherwise group with spacing, `divide-y` or a single top border. Tint any shadow toward the background.
- Nest boxes two deep at most.
- Do not use z-index outside real layers (sticky navigation, overlays, modals).

## Color

- Keep the interface 90 to 95 percent neutral, with at most one accent, saturated below 80 percent, used for actions and focus.
- Use a near-black ink, never `#000`. Do not mix warm and cool grays.
- Define tokens in OKLCH through the shadcn theme variables, and check contrast: 4.5:1 for body text, 3:1 for large text and UI boundaries.
- Support dark mode through tokens, not by duplicating components.

## Components and forms

- One primary button style and one secondary style. Exactly one primary action per view.
- One radius scale (for example sharp 4/6/8 for developer and finance tools, soft 8/12/20 by default) applied everywhere.
- Labels sit above inputs, errors below, helper text in between. Never use a placeholder as the label.
- Touch targets at least 44px. Visible focus ring: 2px in the accent color with a 2px offset.
- Loading uses skeletons shaped like the content, not a lone spinner. Empty states say how to fill them.
- One icon set with one stroke width. Lucide is shadcn's default and fine; Phosphor is the alternative. Never emojis in UI, copy or alt text.

## Motion

- Animate `transform` and `opacity` only. Never `transition: all`, never width, height, top, left or margin.
- Hover in about 150ms and out about 120ms; menus and popovers under 300ms with ease-out, never ease-in.
- Curves: `cubic-bezier(.2,.8,.2,1)` for UI and `cubic-bezier(.22,1,.36,1)` for entrances. No bounce or overshoot on UI controls.
- Press feedback: `scale(0.97)` to `scale(0.985)` or a 1px move down.
- Hover a linked card up about 2px; zoom an image 1.02 to 1.03 inside its frame. No tilt, glow or shine sweep.
- Popovers grow from their trigger (`transform-origin` at the trigger); modals stay centred.
- Put hover effects behind `@media (hover: hover) and (pointer: fine)`.
- Honour `prefers-reduced-motion` from MOTION 4 up. Anything that moves for more than 5 seconds gets a pause control.
- Do not fade in every section on scroll, parallax text, or hijack scrolling.
- Isolate continuous animation in small memoized client components and drive it with motion values (`useMotionValue`, `useTransform`), never React state. Clean up every effect.

## Copy and content

- Headings contain a noun and say what the thing is. The first screen of a marketing page states what is offered and one concrete fact.
- Buttons are a verb plus an object ("Create invoice"), never "Learn more", "Discover" or "Click here". At most two actions in a hero.
- Ban filler: elevate, unlock, unleash, empower, seamless, effortless, cutting-edge, next-gen, world-class, revolutionary, leverage, robust, powerful, supercharge, game-changer, "in today's fast-paced world".
- Never invent stats, testimonials, customer logos or quotes. No "Acme", "Nexus" or "John Doe" placeholders and no suspiciously round numbers such as 99.99%; use realistic, clearly marked sample data.
- No em dashes, exclamation marks or emojis in UI copy.
- No decorative tells: section-number eyebrows (`001 / Capabilities`), version labels in the hero, decorative status dots, scroll cues, locale or weather strips, fake product UI built from styled divs.

## Pre-flight

- Design read and dials stated, and the result matches them.
- Mobile collapse holds at 390px and 320px with no horizontal scroll.
- Loading, empty, error, disabled, hover and focus states exist and were seen.
- Keyboard path works and the focus ring is visible.
- Reduced motion respected; no layout shift on interaction.
- One system: buttons, cards, radii, icons and tokens are consistent; no default-state registry components remain.
- Copy passes the filler and placeholder bans.
