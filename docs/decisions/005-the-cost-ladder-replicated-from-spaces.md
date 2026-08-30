# ADR 005: The cost ladder, replicated from `spaces` unchanged

- **Status:** Accepted
- **Date:** 2026-08-30
- **Source:** `adr-harvest/spaces/001, 002, 004, 005, 007, 008, 011, 014, 015`; `docs/intent/rita.md` § 2.4

## Context

`spaces` built and measured a retrieval ladder — exact cache → semantic cache → small model →
large model → human handoff — and recorded thirteen decisions around it. `rita` needs the same
thing for a different corpus. Re-deriving it would be re-deciding what was already decided and
measured once; deviating would forfeit the comparison.

## Decision

Replicate `spaces/014` and its supporting records:

| Rung | Mechanism | Cost |
| :--- | :--- | :--- |
| 0 | exact match on the question within one `knowledge_version` | $0 |
| 1 | local ONNX `all-MiniLM-L6-v2` via `informers`, `vector(384)` in pgvector, cosine τ ≥ 0.90 | $0 |
| 2 | small model on Groq, the cheapest that cites | metered |
| 3 | large model on Anthropic | metered |
| handoff | "no reliable context" — a rung, never a 500, never an unsourced answer | $0 |

Rungs 2–3 accept an answer only if `cited ⊆ retrieved` (`spaces/015`). Model ids live in
`config/initializers/llm.rb`, never in code, chosen against current pricing at implementation
(`spaces/011`); API keys come from the environment; a missing key falls through to the next
rung (`spaces/001`, `008`). No judge runs inside a request (`spaces/005`). Postgres 17 with
pgvector is the only store (`spaces/002`). Every answer records rung, USD and latency.

## Consequences

- The Costs screen (ADR 003) is a `report` over the `answers` table, nothing more.
- Generating a full MDX draft is a rung-3 job by nature; the ladder's value in `rita` is in
  the retrieval turns before it, and in refinement turns that hit the caches.
- Bad: `spaces/014` was measured once under a rule changed the same afternoon and never
  re-measured. `rita` inherits an unre-measured ladder and must measure it itself.

## Post seed

- **Angle:** copying a decision verbatim as the deliberate choice — replication as the
  cheapest form of evaluation.
- **Tension:** the ladder was designed for Q&A turns; `rita`'s expensive turn is a draft that
  no cache can serve. Does the ladder still earn its place, or only its report?
- **Payoff or cost:** unproven; the first hundred `answers` rows decide.
