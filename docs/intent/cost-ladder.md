# Intent: answers climb a cost ladder, and every answer explains itself

> **Status: confirmed by interview — 2026-08-30** (`self-contained.md`). Downstream: ADR 005,
> 013 (011 and 012 stay ADR→ADR). Provenance: `adr-harvest/spaces/001, 002, 004, 005, 007, 008,
> 011, 014, 015`.

- **Outcome:** nothing answers a question except `Ladder.ask`. A question climbs exact cache →
  semantic cache → small model → large model → handoff, stopping at the first rung that answers,
  and a rung answers only if every id it cites was retrieved. Every answer writes a row with rung,
  model, tokens, USD and latency. Drafting a post is not a rung — it is a job with its own
  budget. Nothing is optimised before it is measured.
- **User:** the author, who asks dozens of questions a day and wants most of them free; and the
  reviewer, for whom a model call inside a request without a budget is the finding.
- **Why now:** the corpus is ~460 ADRs with seeds; the questions asked over it repeat and
  paraphrase. Paying a large model for every one of them is the obvious design and the wrong one.
- **Success:** the cost report shows most answers never reaching rung 3; a handoff is a
  rendered outcome, never a 500; the suite runs with no API key; a per-turn budget in ADR 013 is
  held, and the draft leaves the request.
- **Constraint:** two `Net::HTTP` clients and no SDK gem; model ids in an initializer; keys from
  `ENV`; a missing key falls through to the next rung; no judge inside a request; `cited ⊆
  retrieved` at every rung; the local embedder pinned to a revision.
- **Out of scope:** streaming tokens to the client; a judge or eval in the request path;
  agents, tools, multi-step reasoning; fine-tuning.

## Why I believe this

- **Measured once, on the predecessor corpus.** The one eval run of `spaces` (2026-08-26, 27
  questions in four groups) had 25 of 27 answers never reaching the large model, at $0.00024 per
  answer against $0.00319 for a rung-3-only baseline — 13× cheaper. τ for the semantic rung was
  chosen on the same paraphrase subset it was then scored on, and the rung-3 citation rule
  changed the same afternoon and was never re-measured (`spaces/014`). The number is real and
  the method is weak; `rita` owes its own `rake evals` (owed.md).
- **A citation outside the retrieved set was a security finding before it was a rule.** A
  read-only audit rated rung 3's "any cited set" MEDIUM: prompt injection through corpus text
  could plant a false answer that rungs 0/1 then cache for everyone. The fix chosen was stricter
  than the audit's one-word change — miss the rung entirely — and the reviewer's challenge
  ("one invented citation now costs a human — intended?") was answered on record: "an answer
  citing a post it was never shown is wrong, not merely expensive" (`spaces/015`).
- **A missing key that falls through was reused to fix a bug one PR later.** The same
  code path that handles "no key" handled "provider down", "model returned nonsense" and then
  "local embedder unavailable" — the member got a handoff instead of no reply (`spaces/008`).
  Its cost is the one ADR 012 addresses here: in prose logs, those four causes looked identical.
- **The first draft attempt through the ladder stalled on `max_tokens`.** Not a number problem;
  the shape was wrong — a draft needs the thread, the header and thousands of tokens, and will
  never repeat, so no cache rung can serve it (ADR 011, the build).
- **"Seconds" was false by construction.** The first intent promised a draft in seconds; a
  rung-3 draft of a few thousand tokens takes tens of seconds to minutes. Retrieval over 2,561
  chunks by sequential scan took ~3 ms and one embedding ~1 ms on 2026-08-30 — so the danger is
  optimising the cheap part (an HNSW index "for safety") and not the slow one (ADR 013).
