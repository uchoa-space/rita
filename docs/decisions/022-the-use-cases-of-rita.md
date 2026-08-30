# ADR 022: The use cases of `rita` — the domain declared before the backlog

- **Status:** Accepted
- **Date:** 2026-08-30
- **Source:** `docs/intent/derived-screens.md`; `docs/intent/rita.md` § 2.2–2.3; `docs/screens.md`; the M1 interview (milestone 8)

## Context

`cuy` derives everything from use-case headers (ADR 002), so before any backlog is scheduled
the domain must be declared. M1 is a live prototype of the chat walkthrough with a scripted
ladder and drafter. The header is the API doc (ADR 018) and `rita:explain` will be the living
truth once code exists; this record is the catalogue's birth record.

## Decision

Eight use cases, headers in full:

| Use case | Kind | Header |
| :--- | :--- | :--- |
| `Chat::Thread` | Query | `returns thread:, messages:` (last 50); `renders :chat, say: :say` |
| `Chat::Open` | Command | no `accepts`; `leaves thread: :open`; `invalidates :thread` |
| `Chat::Say` | Command | `accepts thread:, text:` (≤ 4000); `once: [:thread, :text]`; `invalidates :thread` |
| `Post::Start` | Command | `accepts thread:, source:`; `leaves post: :seeded`; `invalidates :thread` |
| `Post::Draft` | Command (job) | `accepts post:`; `requires post: :seeded`; `leaves post: :drafted`; `once: [:post]`; `invalidates :thread` |
| `Post::Refine` | Command (job) | `accepts post:, text:`; `requires post: :drafted`; `leaves post: :drafted`; `once: [:post, :text]`; `invalidates :thread` |
| `Post::Approve` | Command | `accepts post:`; `requires post: :drafted`; `leaves post: :approved`; `invalidates :thread` |
| `Post::Publish` | Command | `accepts post:`; `requires post: :approved`; `leaves post: :published`; `once: [:post]`; `invalidates :thread` |

`once:` keys are the `accepts` that make the intent (ADR 015); `Approve` declares none — a
second approval is idempotent by its `requires`. Every `Post` command invalidates `:thread`:
drafts and status changes land in the chat via `changes_after` (the draft is a message,
ADR 009); the board joins when it exists. `Refine` enters now — ADR 011 decides it, intent
§ success 2 rests on it. Failure codes are body outcomes (the ADR 015 catalogue), never header
words; only `Publish`'s are worth prose — `failure(:not_markdown)`, `failure(:exists)`.

Candidates wait for their screen (one real demand, ADR 003) or for N ≥ 2 (ADR 002):
`Post::Board`, `Corpus::Projects`/`Documents`/`Document`, `Costs::Report`. `corpus:ingest` is
a rake task; `Ladder.ask` and the `Drafter` are infrastructure behind `Say`, `Draft` and
`Refine` (ADR 011) — never use cases. The status graph seeded → drafted → approved → published
(plus `thread: :open`) is what `rita:verify` validates and `Rita::Seed.reach` walks (ADR 016).
ADR 006's "three commands" is amended in place to these commands (ADR 019: no code cites 006).

## Consequences

- `rita:explain` becomes the living doc once the code exists; this record is not maintained, it
  is superseded (ADR 000). An app inheriting the infrastructure begins with its own 022.
- A use case added without amending this record is caught in review (ADR 017), not by a tool.
- Bad: headers written before code will be wrong somewhere; each correction is a diff to this
  ADR while nothing cites it (ADR 019), a new record after.

## Post seed

- **Angle:** the whole domain declared in eight headers before a single route exists.
- **Tension:** a hand-written catalogue against the derived `rita:explain` that will replace it.
- **Payoff or cost:** unproven — the first header the build proves wrong.
