# ADR 015: Commands are unsafe to retry unless the header says `once:`; one failure vocabulary, one status per class

- **Status:** Accepted
- **Date:** 2026-08-30
- **Source:** interface review of ADR 002, 006, 007, 010, 011, 013, 014; `adr-harvest/cuy/0014` (names `once:` as a header word a re-runnable command might earn); the derived routes in `rita:explain` (`POST /chat/threads/:thread_id/say`)

## Context

Three commands cost something when they run twice: `Say` pays the ladder, `Draft` pays the large
model, `Publish` writes a file. A Turbo double-submit, a refresh on a 422, or a Solid Queue retry
is a second run. Nothing in the header vocabulary says whether a command may be repeated, so
every caller decides by accident. Separately, the dispatcher answered in three shapes — a
rendered screen, a Turbo Stream, and a JSON dump of `result.to_h` for a query whose archetype was
not drawn — and the failure codes the ADRs introduced (`:guard_failed`, `:missing_argument`,
`:invalid_argument`, `:blank`, `:too_long`, `:handoff`, `:budget`, `:not_markdown`, `:exists`)
live in six documents and no catalogue.

## Decision

**`once:`.** A command is unsafe to retry unless its header declares `once: [:thread, :text]` —
the `accepts` keys that make up the intent. `Rita.run` then claims an `attempts` row
(`use_case`, `key` = hash of those values, `request_hash`, `state`, unique on `key`) in one
insert *before* `call`: a unique violation with the same `request_hash` and a finished state
replays the stored result; an unfinished one is `failure(:in_flight)`; a different
`request_hash` is `failure(:conflict)`. The key is derived from the intent — never a UUID or a
timestamp. `Draft`'s claim doubles as its job key; `Publish` keeps `failure(:exists)` on top,
because the file is the truth. Retention: attempts live as long as the thread they belong to.
`rita:explain` lists which commands are `once` and which are not.

**One failure vocabulary.** Every `failure(:code)` any use case, rung or drafter can return has a
row in `config/locales/en.yml` under `errors.domain.<code>`, and boot fails in development and
test when a code found in `app/` has none (the check ADR 007 owed). The catalogue is the locale
file; an ADR that introduces a code names it and it lands there in the same commit.

**One status per class.** A domain, guard or argument failure is 422, rendered in place; an
`accepts` entity that does not exist is 404 in the same layout; a `DefinitionError` or
`PostconditionError` is a 500 with no body detail — a bug. Nothing else. **The JSON fallback is
gone**: a registered query whose archetype is not drawn is a `DefinitionError` at boot, not an
endpoint. What a query returns is never observable as a serialisation of its records.

**Routes carry verbs on purpose.** `POST /<ns>/<entity>/:id/<command>` and `POST /<ns>/<command>`
are derived from the header; commands are actions and their names are verbs. This is not REST
and does not pretend to be; the header is the contract, the route is a derivation.

## Consequences

- A retried `Say` is served from `attempts`, costs nothing, and the `answers` table stays honest.
- One more table, one header word, one boot check.
- Bad: `once:` is a decision per command; the default (unsafe) is the one that bites when
  forgotten. `rita:verify` warns on a command that writes an `Answer` and is not `once`.

## Post seed

- **Angle:** the header word a framework predicted it would need one day, needed on day one by
  the first app whose commands cost money.
- **Tension:** derive everything from the header, until the thing to derive is "may this run
  twice?" — a property no route, form or guard can express.
- **Payoff or cost:** unproven — the first `failure(:in_flight)` that replaced a second invoice.
