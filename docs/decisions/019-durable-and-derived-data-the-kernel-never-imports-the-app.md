# ADR 019: Durable and derived data are migrated differently; the kernel never imports the app; unused gems leave

- **Status:** Accepted
- **Date:** 2026-08-30
- **Source:** `docs/intent/trust.md`; deprecation review of ADR 001, 005, 006, 008, 012, 013, 016; `spaces/004` (one embedding model), `spaces/011` (a vendor retired the rung-2 ids mid-build), `inventario/0003` (a dependency-rule test); the `Gemfile` as left by `rails new`

## Context

Nothing here says what may be thrown away. The corpus tables can be rebuilt by `corpus:ingest`
in ninety seconds; `answers`, `posts` and the chat cannot be rebuilt at all. A change of
embedding model would re-embed the chunks and leave `answers.question_embedding` comparing
vectors from two spaces — the semantic cache would hit wrongly, in silence. An ADR deleted from
the archive would take a post's source with it. `lib/rita/` eager-loads `app/use_cases`, so the
"extract a gem later" of ADR 001 is a rewrite, not a move. And the Gemfile still carries what
`rails new` put there: a browser driver the tests refuse, an image pipeline for a page with no
images, a deploy tool for a project that does not deploy, a CSS compiler for a kit that does
not exist.

## Decision

**Two kinds of tables.** *Derived*: `projects`, `documents`, `chunks`, `corpus_state` — may be
dropped and rebuilt by ingest; their migrations may be destructive. *Durable*: `answers`,
`posts`, `post_sources`, `chat_threads`, `messages`, `attempts` — migrations are additive
(expand → backfill → contract, the contract in its own later change) with a `down` that has
been run. No table is both.

**The embedder is part of the version.** `corpus_state` records the embedding model id; changing
it bumps `knowledge_version` and re-embeds the chunks, so rungs 0–1 never compare an answer
embedded under one model with a question embedded under another. Old `answers` rows keep their
vectors and are simply never served again — they are history, not cache.

**Documents retire, they do not die.** Ingest never deletes a `Document`; a file gone from the
archive sets `retired_at`. A `Post` whose source is retired says so on its header; the source
text stays readable.

**The kernel never imports the app.** `lib/rita/` references nothing under `app/`; the app
registers its use cases and archetypes with the kernel at boot (`config/initializers/rita.rb`),
not the other way round. One test walks `lib/rita/**` for `Chat::`, `Post::`, `app/` and fails on
the first hit — the dependency-rule test. Extraction (out of scope, ADR 001) is then a move.

**Vendor retirement is a rung skip.** A model id that stops existing is `provider_failed` on the
`Answer` row (ADR 012) and a fall-through (ADR 005); no boot check calls a provider.

**Unused gems leave.** `capybara`, `selenium-webdriver` (ADR 016), `image_processing` (ADR 013),
`kamal`, `thruster` (deploy is out of scope), `tailwindcss-rails` (ADR 008: a kit is a directory
compiled elsewhere, if ever) — each removed in its own change, back when an ADR asks. A gem with
no consumer is zombie code with a version number.

**Amend in place only before the code exists.** An ADR is edited in place while nothing built
depends on its text (today's 005, 009, 010); once code cites it, a change is a new record that
supersedes, per ADR 000.

## Consequences

- `owed.md` gains: the embedder id in `corpus_state`, `retired_at`, the dependency-rule test, six
  gem removals, and markers on the provisional pieces that predate ADR 017 (`Journal`, the
  stash from the stopped Post stream).
- Bad: two migration disciplines for one small schema; the table list above is the whole rule.

### Tension to watch

A "quick" migration on `answers` because "it's my own data" — the ledger is the one thing every
budget, report and eval reads, and the one thing no task rebuilds.

## Post seed

- **Angle:** deciding what may be thrown away before there is much to throw — and finding the
  Gemfile already full of things nobody would miss.
- **Tension:** one user, one machine, "just drop the table" against a cost ledger that is the
  project's only measurement.
- **Payoff or cost:** unproven — the first embedder change that does not poison the cache.
