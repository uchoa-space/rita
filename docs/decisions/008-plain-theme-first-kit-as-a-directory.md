# ADR 008: A plain, classless theme first; a kit is a directory that may come later

- **Status:** Accepted
- **Date:** 2026-08-30
- **Source:** `docs/intent/derived-screens.md`; `adr-harvest/cuy/0005`, `cuy/0015`, `cuy-kit-tailwind/0001`; `freeze/cuy/docs/screens.md` § Theme (consulted per ADR 001); `docs/intent/rita.md` § 2.2

## Context

`rita` and the blog it writes for are the same author's; the blog is Tailwind Plus *Spotlight*.
The tempting move is to give `rita` the same look on day one. `cuy` tried the equivalent —
Material Design 3 in the kernel — and reverted it the same day (`cuy/0005`), then found the
Tailwind Plus palette failing its own contrast rule at 2.21:1 (`cuy/0015`,
`cuy-kit-tailwind/0001`). A kit adopted before a screen exists is styling nothing.

## Decision

One stylesheet, plain and classless: a dozen `--rita-*` tokens on `:root` (a background never
travels without its `on-` pair), dark by `prefers-color-scheme`, layout keyed to `data-*`
attributes and elements, `prefers-reduced-motion` honoured. Contrast (4.5:1) and heading order
are checked at boot. No marks in v1 — a theme with no marks is a valid theme. Tailwind stays in
the repo only as a compiler: if a kit comes, it is a directory (`@apply` from the Spotlight
snippets into `data-*` rules, `source(none)`, zero class selectors in the output — verified by
`tr '}' '\n' < kit.css | grep -c '^\.'` → 0), swapped by one `stylesheet_link_tag`, and audited
at boot like the plain theme.

The tokens are a contract, named once (2026-08-30, reconciled between `rita.css` and the Figma
prototype — `docs/figma.yml`): `background`, `surface`, `primary`, `success`, `danger`, `muted`,
each with its `on-` pair; `line` (stroke only); `user` (the tint of the user's turn — the role is
still named in words, ADR 009); `focus`; and three non-colour tokens `space`, `radius`, `target`
(44px). The code built first with `bg`/`accent`/`border` and a `0.5rem` radius; the Figma names are
the ones kept, the rename is owed to the code, radius is 4 or 6.

## Consequences

- `rita` is honest about being undesigned until a screen has earned a kit.
- The blog's identity stays the blog's; `rita` is the workshop, not the shop window.
- Bad: the first demo looks plain. Accepted — the demo is the draft in the chat, not the chrome.

## Post seed

- **Angle:** refusing your own blog's design system for the tool that feeds the blog, because
  the last two attempts at "kit first" in this lineage cost a day each.
- **Tension:** one identity across two repos versus a theme that cannot yet fail contrast.
- **Payoff or cost:** unproven — measured the day a Spotlight kit is compiled and boots green.
