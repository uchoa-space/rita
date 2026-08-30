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
  `Draft` leaf: markdown rendered, with the actions the header derives — `Refine`, `Approve`,
  `Publish`. The true render is the blog running `next dev` after publish.
- **Actions are absent, never disabled.** `Publish` exists only when `requires post: :approved`;
  `Approve` only when a draft exists. No greyed control without a stated reason.
- **States.** Empty: the query's `intent` and one button per no-keyword command. Failed: the
  `failure(:code)` rendered as a message where the reader is — handoff included — never a toast.
  Loading: the typing indicator. Happy: the thread.
- **Obligations.** Thread is `role="log"` `aria-live="polite"`; every message named by its role;
  composer labelled; focus returns to the composer after send; roles never told apart by colour
  alone; every action keyboard-reachable; 44px targets on the phone shape.
- **Slice 1 is `chat` alone.** `board`, `list`/`detail`, `report` wait until the conversation has
  produced a real draft.

## Consequences

- `Thread`/`Say`/`Draft` are the first three leaves the vocabulary needs (ADR 004).
- A markdown renderer is a new dependency (`commonmarker`), used only by the `Draft` leaf.
- Bad: no cancel mid-stream means a long rung-3 answer is waited out. Accepted for one user.

## Post seed

- **Angle:** designing a chat as a server-rendered archetype in 2026, against every client-side
  assumption the category carries.
- **Tension:** the assistant-ui anatomy everyone recognises versus a runtime that refuses
  optimistic echo and cancellation on purpose.
- **Payoff or cost:** unproven — the four states of `chat`, rendered and tested as strings.
