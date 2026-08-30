# ADR 010: Kernel decisions taken where the `cuy` ADRs were thin

- **Status:** Accepted
- **Date:** 2026-08-30
- **Source:** the kernel build report (commits `34aa514`..`c139d16`); `adr-harvest/cuy/0002, 0004, 0006`; `freeze/cuy/docs/use-cases.md` and `lib/cuy/{use_case,run,routes,registry,graph,coercion}.rb`, consulted per ADR 001

## Context

ADR 001 said: rewrite from the ADRs, consult the frozen code when an ADR is too thin, and record
the gap. The rewrite found five gaps — the ADRs state principles, not shapes — and made calls
that either follow the frozen code or deliberately diverge from it.

## Decision

Consulted, then followed the frozen shape: the DSL surface (`intent`, `accepts` name→type,
`requires`/`leaves` entity→status, `returns`, `invalidates`, `renders`); `path` derived from
namespace and name, overridable with a string; the status predicate is `<status>?` on the
entity; `invalidates` resolves namespace-local first, then registry-wide; `rita:verify` checks
unproduced statuses, unconsumed statuses, cycles, path collisions and dangling invalidations.

Diverged on purpose:
- `Rita.run` order is coerce → `requires` → call → `returns` → `leaves`; an invalid coercion is
  `failure(:invalid_argument)` and a failed guard `failure(:guard_failed)` — values, not raises
  (ADR 007).
- `leaves` may name an entity absent from `accepts` (a command that *creates*; verified on the
  result). The frozen gem required it in `accepts`.
- The body is uniformly `def call(**accepts)`; no `initialize` with keywords.
- Commands answer POST only.
- The run/registry seam is `Rita::Seam` — `Rita::Kernel` would shadow `::Kernel` inside the
  namespace.
- `DispatchController` rendered JSON with forgery protection skipped for one afternoon; since
  `14f7673` queries draw their archetype, commands answer a Turbo Stream or a 303, forgery
  protection is on. The JSON fallback for an undrawn archetype was removed by ADR 015.

## Consequences

- The kernel is `lib/rita/` at `c139d16`; `rita:explain` and `rita:verify` run green on an empty app.
- Each divergence is one line to reverse; each is here so it is not re-decided by accident.
- `Rita::Command`/`Rita::Query` no longer self-register (they produced phantom `/rita/command`
  routes); only named subclasses do.

## Post seed

- **Angle:** what "rewrite from the ADRs" actually costs — five places where the record said
  *why* and never said *what*, and the code had to be read after all.
- **Tension:** fidelity to the lineage versus the freedom the rewrite was for.
- **Payoff or cost:** partly paid — the kernel exists; whether the divergences hold is the
  `chat` screen's to prove.
