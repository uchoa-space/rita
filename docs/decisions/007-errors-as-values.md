# ADR 007: Errors as values — no exception crosses a layer boundary to signal a domain outcome

- **Status:** Accepted
- **Date:** 2026-08-30
- **Source:** `docs/intent/errors-as-values.md`; the `wise` lineage in `adr-harvest`: `clocky/0002` (origin, 2026-07-23, `Result = Data.define(:value, :error)` replacing five `raise` sites), `inventario/0001` (the rule as stated in the title, 2026-07-26), `clockyy/0002` (`deconstruct_keys`), `bench/0007`, `labs-wise/0003`, `enterprise/0005` (the same move applied to process); `freeze/cuy/docs/use-cases.md` and `lib/cuy/result.rb` (`ok(**data)` / `failure(code, message:, **data)`, consulted per ADR 001 — no `adr-harvest/cuy/` record covers it); `adr-harvest/spaces/007`

## Context

Rails' default is to raise: `save!`, `find`, `rescue_from` turned into a flash. The lineage
abandoned that five weeks ago and has restated the rule in every project since, each time
against code that raised — and `imale-old` records the one project that went the other way as
the counter-example. Two `rita`-specific reasons on top: a derived screen cannot draw a `raise`
(it has no code, no data, no place to render — the archetype's failed state needs a value), and
the ladder's handoff is "no reliable context", an outcome, not an error (`spaces/007`).

## Decision

Raising is reserved for bugs and infrastructure: a `DefinitionError` at boot, a dead database.
Every domain outcome is a `Rita::Result` — `ok(**data)` or `failure(code, message: nil,
**data)`, frozen, `ok?`/`failure?`, `deconstruct_keys` for pattern matching — returned by
`call` and carried intact across every boundary: dispatcher, Solid Queue job, Turbo stream,
screen. ActiveRecord's own errors-as-values (`save` → `false`, errors on the object) is leaned
on, not replaced. `returns` is held on the ok branch in both directions: an undeclared or
missing key is a `DefinitionError`. A failure renders as the archetype's failed state, where
the reader is (`errors.domain.<code>` with the result's data as interpolations); in `chat` it
is a message. `failure(:handoff, …)` is the ladder's last rung. A `rescue` inside a use case
body is the smell.

## Consequences

- A raise inside a job is diagnostically a bug (retry, stays pending) — never confused with a
  domain rejection. The distinction survives all the way to the screen.
- Every branch a screen can show is enumerable from the body's `failure(:code)` calls, so the
  four states are testable against HTML strings (ADR 003). A code without an `errors.domain.*`
  entry falls back to the result's message today; failing at boot is decided in ADR 015.
- Cost: every write path constructs and propagates a `Result` by hand — more lines per use
  case than exception unwinding, in exchange for the guarantee.

## Post seed

- **Angle:** the rule the author has now written down five times in five weeks, each time
  against their own raising code — and the first project that starts from it instead of
  arriving at it.
- **Tension:** Rails idiom (`!` methods, `rescue_from`) against a kernel that needs every
  outcome to be data it can draw.
- **Payoff or cost:** paid forward in the lineage (`clocky/0002` calls it durable); in `rita`
  unproven — the count of `rescue` lines in `app/` at the first screen is the measure.
