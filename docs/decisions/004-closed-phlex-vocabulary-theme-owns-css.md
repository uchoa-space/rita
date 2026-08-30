# ADR 004: A closed Phlex vocabulary; the theme owns the CSS

- **Status:** Accepted
- **Date:** 2026-08-30
- **Source:** `adr-harvest/cuy/0003`, `cuy/0005`, `cuy-kit-tailwind/0001`, `zep/0010`; `docs/intent/rita.md` § 2.1

## Context

A derived screen stops being derived the moment a view can reach for `class:` or a raw tag.
`cuy` closed the vocabulary to a counted set of Phlex leaves (`Table`, `Field`, `Card`, …),
enforced at runtime and by a static lint, and moved every visual decision into a theme keyed by
`data-*` attributes. `rita` ships with `tailwindcss-rails` from `rails new`; Tailwind is
useful as the *source* of the theme's compiled CSS (`cuy-kit-tailwind/0001`, `@apply`) and
harmful as utility classes in app code.

## Decision

Views are Phlex components from a closed leaf vocabulary under `lib/rita/leaves/`. No `class:`
attribute and no raw HTML tag in `app/`; a leaf that does not exist is added to the vocabulary
with a record, not worked around. The theme is one compiled stylesheet keyed by
`[data-component]`/`[data-state]`, built with Tailwind `@apply` from a single source. Contrast
and heading order are checked at boot (`cuy/0015`), not audited later. `chat` borrows its
message/composer anatomy from assistant-ui's MIT CSS as `@apply` source.

## Consequences

- Two `rita` apps — or `rita` twice — differ only in theme.
- A11y obligations live in the leaf, once: `role="log"` and `aria-live="polite"` on the thread,
  a labelled composer, focus returning after send, roles never told apart by colour alone.
- Bad: every new visual need is a vocabulary change with a record. That is the cost being
  bought on purpose; the escape hatch (`renders :custom`) is counted, not free.

## Post seed

- **Angle:** keeping Tailwind and banning Tailwind classes in the same repository — the
  framework as a compiler input, not a vocabulary.
- **Tension:** speed of `class="flex gap-2"` today against a screen you can no longer prove
  was derived tomorrow.
- **Payoff or cost:** `cuy` shipped Material Design 3 and reverted it the same day (`cuy/0005`);
  `rita` starts from that lesson and has not yet paid its own.
