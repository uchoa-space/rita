# ADR 003: Archetypes exist because a `rita` screen demands them; `chat` is the first

- **Status:** Accepted
- **Date:** 2026-08-30
- **Source:** `adr-harvest/cuy/0004`, `cuy/0013`; `freeze/cuy/docs/intent/chat.md` (draft, never interviewed); `docs/intent/rita.md` § 2.2

## Context

`cuy` closed its screen shapes at seven archetypes (`list`, `detail`, `form`, `overview`,
`compose`, `board`, `report`) with one rule: an archetype is added when a real screen demands
it and none of the existing ones can draw it, and removed when it loses its last screen. It
left `chat` as an uninterviewed draft because no screen had asked for it. The 2026-08-29 intent
draft listed `live` and `ref` as `rita` archetypes; they are not — `live` is a kernel concept
(a screen updating itself over Turbo Streams), `ref` is a field type (`cuy/0013`).

## Decision

`rita`'s archetypes are the ones its four screens draw, in build order:

1. `chat` — the conversation. `Query Thread` (`returns thread:, messages:`) `renders :chat,
   say: :say`; `Command Say` (`accepts thread:, text:`) `invalidates :thread`. Streaming is a
   Turbo Stream append; `turbo-frame[busy]` is the typing state. Server renders, no optimistic
   echo, no cancel mid-stream.
2. `board` — the `Post` pipeline, columns from the status graph.
3. `list` + `detail` — the corpus.
4. `report` — the ladder's cost and cache figures.

Nothing else is built. A screen that fits none declares `renders :custom, because: "…"` and
`rita:explain` counts it. Two escapes on the same archetype mean a missing noun, not a new
archetype. Every archetype renders four states (loading, empty, failed, happy) and is tested
against rendered HTML, never a browser (`cuy/0007`).

## Consequences

- `chat` is the first archetype whose loading state lasts seconds — the documented exception
  to "no skeletons because queries are sub-100ms".
- `overview`, `compose`, `form` are not built until a screen asks. `form` is never declared
  anyway; it is derived from a command's `accepts`.
- Bad: `chat` is designed against one screen. It may generalize badly; that is the intended
  price of "one real screen" over a roadmap.

## Post seed

- **Angle:** the archetype that sat in a drafts folder for nine days because no screen had
  asked for it — and the first project that asked being the one writing about the drafts.
- **Tension:** a closed vocabulary that grows only under demand versus the temptation to
  design `chat` "properly" for every future app.
- **Payoff or cost:** unproven — the four states of `chat`, drawn and tested, are the proof.
