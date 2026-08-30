# ADR 022: The use cases of `rita` — the domain declared before the backlog

- **Status:** Accepted
- **Date:** 2026-08-30
- **Source:** `docs/intent/derived-screens.md`; `docs/intent/rita.md` § 2.2–2.3; `docs/screens.md`; the M1 interview (milestone 8)

## Context

`cuy` derives everything — route, form, guard, screen, staleness — from use-case headers
(ADR 002), so before any backlog is scheduled the domain must be declared. M1 is a live
prototype of the chat walkthrough with a scripted ladder and drafter. The header is the API doc
(ADR 018) and `rita:explain` will be the living truth once code exists; this record is the
catalogue's birth record.

## Decision

Seven use cases, headers in full:

| Use case | Kind | Header |
| :--- | :--- | :--- |
| `Chat::Thread` | Query | `returns thread:, messages:` (last 50); `renders :chat, say: :say` |
| `Chat::Open` | Command | no `accepts`; `leaves thread: :open`; `invalidates :thread` |
| `Chat::Say` | Command | `accepts thread:, text:` (≤ 4000); `once: [:thread, :text]`; `invalidates :thread` |
| `Post::Start` | Command | `accepts thread:, source:`; `leaves post: :seeded` |
| `Post::Draft` | Command (job) | `requires post: :seeded`; `leaves post: :drafted`; `once:` |
| `Post::Approve` | Command | `requires post: :drafted`; `leaves post: :approved` |
| `Post::Publish` | Command | `requires post: :approved`; `leaves post: :published`; `once:`; `failure(:not_markdown\|:exists)` |

Candidates wait for their screen or for N ≥ 2 (ADR 003): `Post::Refine` (ADR 011),
`Post::Board`, `Corpus::Projects`/`Documents`/`Document`, `Costs::Report` — one line each here
when a screen demands them. `corpus:ingest` is a rake task, not a use case. `Ladder.ask` and the
`Drafter` are infrastructure behind `Say` and `Draft` (ADR 011), never use cases. The status
graph seeded → drafted → approved → published (plus `thread: :open`) is what `rita:verify`
validates and `Rita::Seed.reach` walks (ADR 016).

## Consequences

- `rita:explain` becomes the living doc once the code exists; this record is not maintained, it
  is superseded (ADR 000). An app inheriting the infrastructure begins with its own 022.
- A use case added without amending or superseding this record is caught in review (ADR 017),
  not by a tool.
- Bad: headers written before code will be wrong somewhere; each correction is a diff to this
  ADR while nothing cites it (ADR 019), a new record after.

## Post seed

- **Angle:** the whole domain declared in seven headers before a single route exists.
- **Tension:** a hand-written catalogue against the derived `rita:explain` that will replace it.
- **Payoff or cost:** unproven — the first header the build proves wrong.
