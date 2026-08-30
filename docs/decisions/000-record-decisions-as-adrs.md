# ADR 000: Record decisions as ADRs, each with a Post seed

- **Status:** Accepted
- **Date:** 2026-08-30
- **Source:** `docs/intent/rita.md`; the format is `adr-harvest`'s, which `rita` both consumes and feeds

## Context

`rita` exists to turn ADRs into blog posts. Its own decisions are the nearest source of material,
and the corpus it reads (`~/Documents/adr-harvest`) already has a record shape: Status, Date,
Source, Context, Decision, Consequences, Post seed. A decision recorded here in any other shape
would be the one document in the corpus `rita` cannot read the way it reads everything else.

## Decision

One Markdown file per decision under `docs/decisions/`, three-digit numbering, the six sections
above, at most ~40 lines. Every record carries a **Post seed** — Angle, Tension, Payoff or cost —
written at decision time, when the tension is still felt. A record cites the file or commit that
embodies it once one exists. Superseding writes a new record; the old one stays.

## Consequences

- `rita` can ingest its own `docs/decisions/` with no special case — meta-circularity by format.
- A Post seed written before the outcome is known will often have "Payoff or cost: unproven"; that
  is the honest state and is updated, not invented.
- Bad: nothing enforces that a decision gets a file. The discipline is the author's.

## Post seed

- **Angle:** a tool for writing about decisions has to record its own decisions in the format it
  reads, or it is exempt from its own thesis.
- **Tension:** writing the seed before the payoff is known versus waiting until the record is
  "true" — and losing the tension that made it worth recording.
- **Payoff or cost:** unproven — the first post drafted from a `rita` ADR by `rita` is the test.
