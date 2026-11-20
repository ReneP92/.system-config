# Library picks

Adapted from pick-ui-library (see `../NOTICE.txt`). These are deliberate picks: do not substitute alternatives outside this list unless the user asks or the task is not covered, and say so when leaving it.

## Decision order

1. **What the project already uses.** Read `package.json` and `components.json` first. Flag a competitor (for example react-window instead of Virtuoso) but do not churn dependencies unless asked.
2. **shadcn/ui as the component layer** on Tailwind CSS v4. You own the component source and restyle it to the project's tokens.
3. **Radix as the primitive base** for new shadcn projects (`-b radix`, using the unified `radix-ui` package). Use Base UI (`-b base`) or React Aria (`-b aria`) when the project already does. Do not mix primitive libraries in one project.
4. **A specialist library** from the list below for anything shadcn does not cover well.
5. **Effect registries** (Aceternity, Magic UI and the like) last, and only under the rules below.

## Curated list

| Task | Pick | Notes |
| --- | --- | --- |
| Accessible primitives (dialog, popover, menu, select, tabs) | Radix (`radix-ui`) | Base UI (`@base-ui/react`) where already used |
| Complex accessible widgets (date picker, combobox, i18n-heavy forms) | React Aria Components | Strongest accessibility and locale behavior |
| Styled components | shadcn/ui | Always restyled; never in its default theme |
| Command menu (Cmd+K) | cmdk | shadcn `command` wraps it |
| Toasts | Sonner | shadcn `sonner` wraps it |
| Drawers and bottom sheets | Vaul | shadcn `drawer` wraps it |
| OTP and verification codes | input-otp | shadcn `input-otp` wraps it |
| Control panels for tweaking values | Leva | Development and creative tools |
| Animation: springs, layout, exit, gestures | motion (`motion/react`) | Plain CSS for hover and simple fades |
| Animated numbers | NumberFlow | Instead of re-rendering text |
| 3D globe | Cobe | |
| Syntax highlighting | shiki | |
| Dynamic OG images | Satori | |
| Charts | recharts | Liveline for live, time-scrolling data |
| Drag and drop | dnd kit | |
| Long lists and tables | Virtuoso | From about 1,000 rows |
| Shared state | zustand | Local state stays in `useState` |
| Conditional classes | clsx | With `tailwind-merge` via shadcn's `cn` |
| Typed component variants | cva | When a component has real size or intent variants |
| Theme switching without flash | next-themes | |
| Icons | lucide-react | shadcn default; Phosphor as the alternative; one set per project |

## Common mismatches

- Toasts built by hand or with a modal library: use Sonner.
- A `div` dropdown or dialog with manual focus handling: use the primitive.
- A number animated by re-rendering text: use NumberFlow.
- A list of 1,000 or more rows rendered directly: use Virtuoso.
- Shared state threaded through many props: use zustand.
- className ternaries three conditions deep: use clsx or cva.

## Effect registries

Aceternity UI (`@aceternity`), Magic UI (`@magicui`), Motion Primitives (`@motion-primitives`), Animate UI (`@animate-ui`) and coss ui (`@coss`) are in shadcn's built-in registry index, so `shadcn add @namespace/item` works without editing `components.json`. They are third-party code:

- Run `shadcn view @namespace/item` and read the code before adding it.
- Use them only on marketing surfaces or when MOTION is 6 or higher; never on dense app UI.
- At most one hero-grade effect (globe, beams, spotlight, marquee) per page, and none that violates the motion rules in `taste.md`.
- Restyle to the project's tokens and add a reduced-motion fallback.

## Commands

Use the package manager the lockfile indicates (`pnpm dlx`, `npx`, `bunx`); `npx` is shown here.

```sh
# shadcn/ui (needs Tailwind CSS v4; templates: next, vite, start, react-router, laravel, astro)
npx shadcn@latest init -t vite -b radix   # new or un-initialised project
npx shadcn@latest add button dialog       # official components
npx shadcn@latest add @magicui/globe      # registry item, after `view`
npx shadcn@latest view @aceternity/spotlight
npx shadcn@latest search @aceternity -q card
npx shadcn@latest docs dialog             # usage and API reference
npx shadcn@latest add button --diff       # compare a local component with upstream
npx shadcn@latest apply <preset>          # move off the default theme

# Libraries
npm install radix-ui                      # unified Radix package
npm install @base-ui/react
npm install motion                        # import { motion } from "motion/react"
npm install tailwindcss @tailwindcss/vite # Tailwind v4 on Vite; `@import "tailwindcss";` in CSS
```

`shadcn init --defaults` selects the Base UI preset, so always pass `-b` explicitly. A theme from tweakcn (https://tweakcn.com) or a shadcn preset is a quick way to get off the default theme; still adjust it to the design read.

## Sources

- shadcn/ui: https://ui.shadcn.com/docs (CLI: https://ui.shadcn.com/docs/cli, registry index: https://ui.shadcn.com/r/registries.json)
- Radix Primitives: https://www.radix-ui.com/primitives/docs/overview/getting-started
- Base UI: https://base-ui.com
- React Aria Components: https://react-spectrum.adobe.com/react-aria/
- Aceternity UI: https://ui.aceternity.com/docs/cli
- Magic UI: https://magicui.design/docs/installation
- coss ui: https://coss.com/ui/docs
- Motion: https://motion.dev/docs/react
- Tailwind CSS: https://tailwindcss.com/docs
