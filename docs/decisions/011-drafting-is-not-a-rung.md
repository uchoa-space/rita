# ADR 011: Drafting is not a rung — the ladder answers questions; the `Drafter` writes posts

- **Status:** Accepted
- **Date:** 2026-08-30
- **Source:** the build — `app/ladder/ladder.rb`, `app/use_cases/chat/say.rb` (`14f7673`), the `Post` stream stopped at `2e3e3e0` while trying to push a draft through the ladder; ADR 005 § Consequences ("does the ladder still earn its place?")

## Context

`Ladder.ask(text)` is stateless question answering over the corpus: one string in, one JSON
`{answer, cited}` out, `max_tokens 1024`, accepted only if `cited ⊆ retrieved`. That is what
`spaces` built and what `Chat::Say` calls, once per turn, with nothing but the current text.
A post draft is none of that: it needs the thread as context, the `Post` header as outline, an
editorial prompt (`adr-harvest/CLAUDE.md` § Writing the posts), several thousand output tokens,
and it will never repeat — no cache rung can ever serve it. The first attempt to make the draft a
rung-3 call stalled on `max_tokens` in the shared harness; the shape was wrong, not the number.

## Decision

Two paths through one harness. **`Ladder.ask`** stays exactly `spaces`' ladder and serves the
question turns of the chat. **`Drafter`** (`app/ladder/drafter.rb`) is a separate use of the same
`Llm::Client`, always the large model, with its own prompt, its own `max_tokens`, its own
acceptance (`cited ⊆ retrieved` still holds), and it writes an `Answer` row with `rung: "3"` so
cost and latency land in the same table as everything else. Refining a draft is a `Post` command
that runs the `Drafter` again with the thread as context — not a ladder turn. `Chat::Say` remains
stateless by design; conversation memory belongs to the `Post`, which is the thing being talked
about.

## Consequences

- The ladder's value in `rita` is measured on question turns only; the draft is rung 3 by
  construction and is reported as such, not hidden in a cache-hit rate it can never affect.
- Intent § success 2 ("refine tone or sources from the chat") is a `Post::Refine` command, not a
  property of the chat archetype. ADR 009 is amended accordingly.
- The `Drafter` runs in a Solid Queue job and lands by broadcast; it is minutes, not seconds
  (ADR 013).
- Bad: two prompts to keep true, and a harness option (`max_tokens`) that exists for one caller.

### Tension to watch

Someone will "unify" the two paths into an `Llm::Call` with nine options (`json:`, `max_tokens:`,
`cite:`, `context:`, …). The harness (`Llm::Client#complete`) is the only shared thing; `Prompt`
and `Drafter::Prompt` are two files that do not import each other. A harness parameter only one
caller uses — the `max_tokens` the first attempt reached for — is the sign the boundary is
leaking.

## Post seed

- **Angle:** the moment a cost ladder copied verbatim meets the one request it was never
  designed for — the expensive turn that cannot repeat — and the honest answer is a second door,
  not a taller ladder.
- **Tension:** "nothing answers a question except `Ladder.ask`" (`spaces/014`) against a product
  whose main output is not an answer.
- **Payoff or cost:** the `answers` table will show it: question turns climbing, drafts always
  at 3. Whether the ladder earns its place is then a number, not an argument.
