# ADR 009: The `chat` screen — one column first, server-first streaming, the draft is a message

- **Status:** Accepted
- **Date:** 2026-08-30
- **Source:** ADR 003, 004, 007; `freeze/cuy/docs/intent/chat.md` (draft, consulted per ADR 001); `freeze/cuy/docs/screens.md` § Accessibility, Responsive; `docs/intent/rita.md` § 2.2

## Context

The conversation is the product's main surface and the first archetype `rita` draws (ADR 003).
The intent sketched "70% chat + 30% sidebar". Several questions were open: what happens on a
phone, whether the client echoes optimistically or cancels a stream, where the MDX draft shows
up, and what the empty and failed states are.

## Decision

- **Layout.** One column below 1024px: thread, composer, then the `Post` header and retrieved
  chunks as named sections beneath. Two columns above. *Reflow, never hide* — nothing carrying
  information is `display: none` at any width.
- **Streaming.** Server-first: the assistant's message streams as Turbo Stream appends into its
  frame; `turbo-frame[busy]` is the typing state — the documented exception to "no skeletons".
  No optimistic echo, no cancel mid-stream.
- **The draft is a message.** `rita` does not render MDX. A draft is an assistant message with a
  `Draft` leaf: markdown rendered with raw HTML dropped and links `http(s)` only (ADR 014), with the actions the header derives — `Refine`, `Approve`,
  `Publish`. The true render is the blog running `next dev` after publish.
- **Actions are absent, never disabled.** `Publish` exists only when `requires post: :approved`;
  `Approve` only when a draft exists. No greyed control without a stated reason.
- **States.** Empty: the query's `intent` and one button per no-keyword command. Failed: the
  `failure(:code)` rendered as a message where the reader is — handoff included — never a toast.
  Loading: the typing indicator. Happy: the thread.
- **Transitions do not shift.** A state's slot has the height of what replaces it: the typing
  indicator is one message tall, the empty state is one message plus its buttons, the sidebar's
  "no header yet" section is the height of a header. Appends land at the bottom of the log and
  move nothing above them. (CLS — reviewed 2026-08-30.)
- **The acknowledgement of Send is client-side.** Turbo sets `turbo-frame[busy]` before any
  response and the theme draws the typing state from that attribute alone; the user's text stays
  in the composer until `turbo:submit-end`. That is the next paint after the tap, and it is a CSS
  rule — never a server round-trip. (INP.)
- **Append per message, never per token.** `role="log" aria-live="polite"` announces each append;
  a token stream would announce hundreds of fragments and reflow the log on each. A question's
  answer and a draft (ADR 013) each arrive as one append.
- **Obligations.** Thread is `role="log"` `aria-live="polite"`; every message named by its role;
  composer labelled; focus returns to the composer after send; roles never told apart by colour
  alone; every action keyboard-reachable; 44px targets on the phone shape.
- **Slice 1 is `chat` alone.** `board`, `list`/`detail`, `report` wait until the conversation has
  produced a real draft.

## Decided on the way (2026-08-30, from the build and the Figma prototype)

- Rung, USD and latency are a `meta` part of the assistant's `Message` — per-answer traceability
  (intent § success 4) lives on the chat surface, not only on the Costs `report`.
- `Refine` is free text in the composer; a button for it is sugar the Figma prototype drew and
  the code does not need.
- Before a `Post` header exists the sidebar section shows dashes and one sentence, never hides.
- `Sources` is its own leaf in code (Figma drew it as a `Message` part); typing is the `Thread`'s
  busy state in code (Figma drew it as a `Message` variant). The Figma sidecar records both.
- `::Thread` is Ruby core, so the model is `ChatThread`; the header entity stays `thread:`.
- `Command Open` exists: without it `thread: :open` was a status nothing produced (`rita:verify`)
  and the empty state had no keyword-less command to offer.
- The chat is stateless per turn: `Say` hands the ladder the current text and nothing else.
  Refining a draft is `Post::Refine` with the thread as context (ADR 011), not a chat property.
- Streaming for slice 1 is the Turbo Stream response to `Say`'s POST (two appends), the frame busy
  for the whole ladder; a Solid Cable broadcast enters at `ViewResolver.changes_after` when a job
  does. Not validated in a browser — by scope, tests are strings.

## Consequences

- `Thread`/`Say`/`Draft` are the first three leaves the vocabulary needs (ADR 004).
- A markdown renderer is a new dependency (`commonmarker`), used only by the `Draft` leaf.
- Bad: no cancel mid-stream means a long rung-3 answer is waited out. Accepted for one user —
  for questions only; a draft never runs inside a request (ADR 013).

## Post seed

- **Angle:** designing a chat as a server-rendered archetype in 2026, against every client-side
  assumption the category carries.
- **Tension:** the assistant-ui anatomy everyone recognises versus a runtime that refuses
  optimistic echo and cancellation on purpose.
- **Payoff or cost:** unproven — the four states of `chat`, rendered and tested as strings.
