# ADR 012: Events over `ActiveSupport::Notifications`; an `Answer` row explains its own handoff

- **Status:** Accepted
- **Date:** 2026-08-30
- **Source:** `adr-harvest/cuy/0016` (designed 2026-08-23, never built), `spaces/008` § Consequences (the two "Bad" lines), `spaces/014` (the `answers` table as the artefact); the build — `app/ladder/rung/model.rb:49`, `lib/rita/run.rb:79`, `db/migrate/*_create_answers.rb`

## Context

Four questions the one operator will ask: why did this turn hand off; what did today cost, per
rung and per post; is the corpus behind the files on disk; does retrieval find the right chunk.
The second is answerable from `answers` today. The first is not: a rung that misses writes
`logger.warn("[ladder] rung N skipped: …")` in prose and the row keeps only `rungs_tried` — so
"no key set" and "the model invented a citation" look identical in the table, which is the cost
`spaces/008` recorded and `rita` inherited. Nothing carries a request id; a missing key warns
nowhere at boot; `run.rb` logs a postcondition failure as a sentence. `cuy/0016` designed the
fix — events on Rails' own bus, payload keys never values, one fail-open subscriber — and it was
never built there.

## Decision

1. **The row explains the handoff.** `answers` gains `skips jsonb` — one `{rung, reason}` per rung
   that missed, `reason` from a closed set: `nothing_retrieved`, `below_tau`, `missing_key`,
   `provider_failed`, `malformed`, `empty`, `invented_citation`. `rungs_tried` stays. The
   prose warning goes.
2. **Events, not log lines.** Four events over `ActiveSupport::Notifications`, payload keys only,
   never an argument value or free text:

   | Event | Payload keys |
   |---|---|
   | `rita.run` | `key`, `kind`, `outcome` (ok / guard / failure / postcondition), `code`, `duration_ms`, `request_id` |
   | `rita.postcondition_failed` | `key`, `entity`, `declared`, `found`, `request_id` — `error` level: a header that lied |
   | `rita.ladder.rung` | `rung`, `outcome` (landed / skipped), `reason`, `model`, `duration_ms`, `cost_usd`, `request_id` |
   | `rita.drafter` | `post_id` hashed, `outcome`, `model`, `duration_ms`, `cost_usd`, `request_id` (ADR 011) |

   `request_id` is `request.request_id` from the dispatcher, otherwise minted per run and passed
   explicitly, never via a global. One subscriber, `Rita::Instrumentation::LogSubscriber`, JSON
   lines on `Rails.logger`, on in every environment, fail-open (a raising subscriber is rescued,
   logged once at `error`, detached).
3. **Boot says what is missing.** An unset `GROQ_API_KEY` or `ANTHROPIC_API_KEY` is one `warn`
   at boot naming the rung it disables — the second `spaces/008` cost.
4. **No backend, no alerts.** One user on one machine: the `answers` table is the metrics store
   and the Costs `report` (ADR 003) is the dashboard — rung distribution, USD, p50/p95 latency
   from the rows, never an average alone. `rita:verify` gains one check: every use case run in the
   suite emitted exactly one `rita.run`.

## Consequences

- Intent § success 4 ("full cost and latency traceability per answer") becomes a query, and a
  handoff becomes explainable from the row that recorded it.
- OpenTelemetry or Prometheus, should either ever matter, subscribe to the same four events;
  nothing here is written for a vendor.
- Bad: one more column, one subscriber, one boot check to keep true — and a rule (no value in a
  payload) that only review enforces.

### Tension to watch

`answers` has fourteen columns, gains `skips` here, is written by drafts (ADR 011), read for
p95 (ADR 013) and summed for the daily ceiling (ADR 014); `post_id`, `thread_id`, `kind` are next
in line. `Answer` is the cost ledger — one row per paid or cached call — and nothing else. Whoever
needs to tie an answer to a message or a post points *at* it (`messages.answer_id`, as today),
never the other way round.

## Post seed

- **Angle:** the observability design a framework wrote and never built, built first by the app
  that needed to explain a single word — "handoff" — to its one user.
- **Tension:** "just grep the log" for one operator, against a table that already exists and
  cannot answer the only question the operator has.
- **Payoff or cost:** unproven — the first handoff whose cause is read from the row, not the log.
