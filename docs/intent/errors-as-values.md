# Intent: a domain outcome is a value, never an exception

> **Status: confirmed by interview — 2026-08-30** (`self-contained.md`). Downstream: ADR 007,
> 015. Provenance: `adr-harvest/clocky/0002`, `inventario/0001`, `clockyy/0002`, `bench/0007`,
> `labs-wise/0003`, `enterprise/0005`, `spaces/007`; `freeze/cuy/lib/cuy/result.rb`.

- **Outcome:** every use case, rung and drafter returns a `Rita::Result` — `ok(**data)` or
  `failure(code, …)` — that crosses dispatcher, job, Turbo stream and screen intact. Raising is
  for bugs and dead infrastructure only. Every code has one row in `errors.domain.*`, checked at
  boot; every command that pays or writes says `once:` in its header; one HTTP status per class
  of outcome.
- **User:** the reader of a screen, who sees the failure where they are, in words; and the
  reviewer, for whom a `rescue` inside a use-case body is the finding.
- **Why now:** a derived screen has no code of its own — it cannot draw a `raise`. The failed
  state of an archetype needs a value with a code and data. And the ladder's honest exit,
  "no reliable context", is an outcome, not an error.
- **Success:** every branch a screen can show is enumerable from the body's `failure(:code)`
  calls and tested as an HTML string; a raise inside a job is diagnostically a bug (retries, stays
  pending) and never confused with a domain rejection; a retried `Say` costs nothing.
- **Constraint:** ActiveRecord's own errors-as-values (`save` → `false`) is leaned on, not
  wrapped; `returns` is enforced on the ok branch in both directions; the JSON fallback does not
  exist — what a query returns is never observable as a serialisation.
- **Out of scope:** a `Result` monad with `bind`/`map`; typed error hierarchies; a global
  `rescue_from` that turns exceptions into flashes.

## Why I believe this

- **Five projects in five weeks made the same move against their own raising code.** The origin
  is `clocky` (2026-07-23): every write fired a request and reset the form regardless of outcome;
  the fix was that a write *always resolves* with a notice fragment and never raises across the
  wasm/JS boundary. Three days later `inventario` replaced `raise DomainError` at 55 lines of a
  single-file core with `Result` the next morning. `clockyy`, `bench`, `labs-wise` restated it;
  `enterprise/0005` applied it to process. One project went the other way and is recorded as the
  counter-example. This is a pattern the author keeps arriving at, which is evidence of
  conviction, not of measurement — **unmeasured** as a defect-rate claim.
- **Handoff as a rung, not an exception, gave every caller the same behaviour for free.** In
  `spaces` the API, the MCP tool and the eval got identical handoff semantics by calling the same
  ladder; the one cost recorded was observability (a handoff wrote no row), which ADR 012 pays
  here (`spaces/007`).
- **A command run twice pays twice.** Turbo double-submit, refresh on a 422, Solid Queue retry —
  each is a second run of `Say` (the ladder), `Draft` (the large model) or `Publish` (a file).
  No incident measured; the argument is that the default (unsafe) is the one that bites when
  forgotten, so the header must say it (ADR 015).
- **Fewer lines is not the goal.** A `Result` propagated by hand is more code per use case than
  unwinding. The guarantee bought is that the distinction bug/outcome survives to the screen.
  Accepted cost, stated in ADR 007.
