# ADR 002: Command/query separation behind a declarative header — not CQRS

- **Status:** Accepted
- **Date:** 2026-08-30
- **Source:** `adr-harvest/cuy/0002`, `cuy/0006`, `cuy/0014` (Proposed); `docs/intent/rita.md` § 2.1

## Context

Every use case in `rita` is either a `Command` (mutates, `POST`) or a `Query` (reads, `GET`,
draws a screen). The split is what lets the rest be derived: route, form, guard, archetype,
what goes stale. The name invites confusion with CQRS, which `cuy/0002` refused explicitly and
`rita` refuses again: no event store, no read model, no eventual consistency.

## Decision

`Rita::Command` and `Rita::Query` each declare a header — `intent`, `accepts`, `requires`,
`leaves`, `returns`, `invalidates`, `renders` — and the kernel derives routes, forms, guards,
Turbo streams and views from it at boot. `leaves` (postconditions) is **verified** after the
command runs, never performed by the kernel (`cuy/0006`). A query returns its own contract and
never reuses a shared domain read. The split is organizational; both sides hit the same
Postgres.

"One header, N renderers" (`cuy/0014`) is *Proposed* upstream and taken as such: `rita`
derives one renderer, the screen, and takes no position on MCP, mail, chat transports or SMS.

## Consequences

- A use case is a spec you can read in ten lines; `rita:explain` lists them all.
- The header is the only place a screen's shape comes from — nothing in a view names a domain.
- Bad: a command that does not fit the vocabulary has no hatch but `renders :custom, because:`
  (ADR 003); the first one that appears is a signal, not a nuisance.

## Post seed

- **Angle:** a naming collision (CQS vs CQRS) that forces you to say out loud what you are
  *not* building, and the refusal turning out to be the clearer half of the design.
- **Tension:** the header promises to derive everything; every derivation is a place the
  promise can quietly stop being true.
- **Payoff or cost:** unproven in `rita`; `cuy` drew seven archetypes from it before stopping.
