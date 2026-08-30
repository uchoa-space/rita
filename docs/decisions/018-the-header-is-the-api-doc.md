# ADR 018: The header is the API doc; comments cite the ADR; the README is for the five-minute reader

- **Status:** Accepted
- **Date:** 2026-08-30
- **Source:** ADR 002 (the header is the spec), 015 (no JSON surface), 017 (the two mandatory comments); `spaces/000` ("the README stays a description of what runs, not an argument"); `lib/rita/result.rb` (comment style already in use)

## Context

Eighteen decisions and no decision about documentation: the README is still `rails new`
boilerplate, there is no `CLAUDE.md` so an agent only reads the ADRs when a brief tells it to,
and "document the code" has no meaning here. The obvious tools — OpenAPI, YARD on every method —
would document a JSON API this app does not have and restate headers that already say it.

## Decision

**No OpenAPI.** There is no JSON surface (ADR 015). The use-case header — `intent`, `accepts`,
`requires`, `leaves`, `returns`, `invalidates`, `renders`, `once` — is the interface
documentation, and `rita:explain` renders it from the registry. Should a machine-readable spec
ever be needed (an MCP renderer, `cuy/0014`), it is `rita:explain --json`, derived, never a
hand-kept file: one truth, one place.

**Comments say why and name the ADR.** A comment explains an intent the code cannot
(`# ADR 007: every domain outcome is a value`) or carries one of the two claims ADR 017
requires (`# provisional: until …`, `# after freeze/cuy …`). A comment that restates the code is
deleted in review. No YARD, no per-method docblocks: a use case's signature is its header; a
leaf's contract is its row in `docs/screens.md`.

**The README is for the five-minute reader**: what runs, how to run it, the commands, and one
link to `docs/decisions/`. No argument lives there.

**`CLAUDE.md` is the agent's contract**: under forty lines — the reading order (intent, ADR
index, `screens.md`, `owed.md`), the six rules an agent breaks most (`Result` not `raise`, no
`class:`, no raw tag in `app/`, `once:` on paid commands, one dependency per change, review
before `main`), and where to record a new decision. It cites ADRs; it does not repeat them.

**The docs map** is fixed: `docs/intent/` (what and why), `docs/decisions/` (why this way),
`docs/screens.md` (the vocabulary), `docs/figma.yml` (leaf → Figma node), `docs/perf.md`
(measurements), `docs/owed.md` (debts), `docs/reviews/` (history). A new document goes in one of
these or gets an ADR saying why not.

## Consequences

- The interface documentation cannot drift from the code because it is the code.
- Bad: a reader used to OpenAPI has to learn to read a header. `rita:explain` is the bridge.
- Bad: `CLAUDE.md` will be tempted to grow; forty lines is the budget, and ADRs are where the
  overflow goes.

## Post seed

- **Angle:** the API documentation tool this project refuses because its interface is a Ruby
  class declaration that already documents itself.
- **Tension:** "everyone has a Swagger" against a surface that was closed on purpose the day
  before.
- **Payoff or cost:** unproven — the first time a reader asks for a spec and `rita:explain`
  answers.
