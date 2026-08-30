# ADR 007: A use case returns a `Result`; domain failures are values, not exceptions

- **Status:** Accepted
- **Date:** 2026-08-30
- **Source:** `freeze/cuy/docs/use-cases.md` § "The header" and the `Cuy::Result` paragraph; `freeze/cuy/lib/cuy/result.rb` (consulted per ADR 001 — no `adr-harvest/cuy/` record covers this); `adr-harvest/spaces/007`

## Context

Rails' default is to raise: `save!`, `find`, a rescued exception turned into a flash. A
derived screen cannot draw a `raise` — it has no code, no data, no place to render. `cuy`'s
body returns `ok(**data)` or `failure(code, message:, **data)`, and the dispatcher turns a
failure into a 422 rendered *where the reader is*: `errors.domain.<code>` looked up with the
result's data as interpolations. `rita` has a second reason: the ladder's handoff is "no
reliable context" — an outcome, not an error (`spaces/007`) — and a draft the model could not
ground is a value the chat must show, never a 500.

## Decision

`Rita::Command#call` and `Rita::Query#call` return a `Rita::Result`: `ok(**data)` or
`failure(code, message: nil, **data)`, frozen, with `ok?`/`failure?`. Exceptions are for
programmer errors and infrastructure (a `DefinitionError` at boot, a dead database) — never
for a domain outcome. `returns` is held on the ok branch in both directions: an undeclared or
missing key is a `DefinitionError`. A failure renders as the archetype's failed state, in
place; in `chat` it is a message. `failure(:handoff, …)` is the ladder's last rung.

## Consequences

- Every branch a screen can show is visible in the body as a `failure(:code)` — the four
  states are enumerable, so they are testable against HTML strings (ADR 003).
- `errors.domain.*` becomes the catalogue of everything that can go wrong for a user; a code
  without a translation is a boot error, not a blank toast.
- Bad: bodies grow `return failure(...) if` guards and the discipline is not to hide one
  behind a `rescue`. A `rescue` in a use case body is the smell.

## Post seed

- **Angle:** the screen you cannot derive from an exception — why "errors as values" is a
  rendering decision before it is a style preference.
- **Tension:** Rails idiom (`!` methods, `rescue_from`) against a kernel that needs every
  outcome to be data it can draw.
- **Payoff or cost:** unproven — the count of `rescue` lines in `app/` at the first screen
  is the measure.
