# ADR 013: Performance budgets per kind of turn; the draft is a job; nothing is optimised unmeasured

- **Status:** Accepted
- **Date:** 2026-08-30
- **Source:** `docs/intent/cost-ladder.md`; review of ADR 000–012 and `docs/intent/rita.md` against the performance skill; `spaces/002` ("an HNSW index is one migration away"), `spaces/004` (embedder cold load, eager in production only), `spaces/009`, `cuy/0015` (webperf as a boot rule); one measurement taken 2026-08-30 before the review: retrieval over 2,561 chunks by seq scan + top-N heapsort in ~3 ms, one embedding in ~1 ms

## Context

The intent's first success criterion — "a coherent MDX draft in seconds" — is the project's only
performance number and it is false by construction: a rung-3 draft of a few thousand tokens takes
tens of seconds to minutes (ADR 011). ADR 009 then holds the Turbo frame `busy` for the whole
call inside the request, which is fine for a three-second question and wrong for a minute. The
rest of the surface is already cheap (2.4 KB HTML, 5.9 KB CSS, no images, one importmap) and the
danger is the opposite one: optimising what nobody measured — an HNSW index "for safety", a cache
in front of a 3 ms query, a font that costs the only network bytes the page has.

## Decision

**Budgets, per kind of turn**, measured from `answers.latency_ms` (ADR 012) as p50/p95, never an
average alone:

| Turn | Budget |
|---|---|
| question, cache rung (0–1) | p95 ≤ 100 ms |
| question, model rung (2) | p95 ≤ 3 s |
| question, model rung (3) | p95 ≤ 10 s |
| draft (ADR 011) | minutes; not a request — see below |
| page (`GET /chat/…`) | server time p95 ≤ 100 ms; HTML ≤ 50 KB; CSS ≤ 20 KB; 0 image bytes; 0 font bytes (system sans stack); 0 JS beyond the importmap |
| Core Web Vitals, on the happy `chat` screen | LCP ≤ 1.0 s (local), INP ≤ 200 ms, CLS ≤ 0.1 across every state transition — measured by Lighthouse, several runs, the way `cuy/0015` found its contrast bug; the numbers go in `docs/perf.md` |

**The draft is a job.** `Post::Draft` enqueues on Solid Queue and returns at once; the assistant
message appears with the frame busy, and the finished draft arrives by Turbo Stream broadcast over
Solid Cable through `ViewResolver.changes_after` — the seam ADR 009 left. No request ever waits
on the large model for a draft.

**Eager where it serves.** The embedder loads at boot in every environment that serves requests
(`spaces/004` said production only; here development is production).

**No index until the plan says so.** Retrieval stays a sequential scan while
`EXPLAIN ANALYZE` on `Chunk.retrieve` is under 50 ms; the corpus grows only by ingest and is
bounded by the archive. An HNSW index is added by a migration whose message quotes the plan
before and after, and is reverted if the plan did not move.

**Bounded lists.** `Chat::Thread` returns the last 50 messages with `includes(:answer)`; older
turns are not lost, they are not drawn. The rule generalises: no query returns an unbounded
collection.

**Rungs 0–1 are not optimised.** Their fixed cost per question (one embedding, one query, ~5 ms)
is accepted even though they rarely land (ADR 005); a cache in front of them is a revert.

**A ledger of attempts.** `docs/perf.md` records every performance change — kept and reverted
alike — as idea, baseline → result, verdict, why. A change that lands inside run-to-run noise is
reverted; "neutral" is not a keep. The page budgets above are boot-time checks beside the
contrast audit (ADR 008); the turn budgets are rows in the Costs `report`.

## Consequences

- Intent § success 1 is restated: a *question* answers in seconds; a *draft* arrives in minutes,
  as a message, while the chat stays usable.
- Solid Queue and Solid Cable stop being installed-and-unused; the seam in `changes_after` gets
  its first real caller.
- Bad: a job means a worker process in development (`bin/dev` already runs one via Procfile.dev)
  and one more thing that can be "up" or not; the boot warning (ADR 012) should say so.

## Post seed

- **Angle:** the one performance number the project had was in the intent, was wrong, and was
  wrong in the reassuring direction — and every other performance temptation was in the
  opposite direction, optimising a 3 ms query.
- **Tension:** the pull to add the index, the cache and the font "while we're here", against a
  ledger that would have to show each one moved a number.
- **Payoff or cost:** unproven — the first `answers` p95 per rung against the table above.
