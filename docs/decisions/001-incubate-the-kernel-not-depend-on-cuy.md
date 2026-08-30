# ADR 001: Incubate the `cuy` kernel in-repo, rewritten from its ADRs — not a dependency

- **Status:** Accepted
- **Date:** 2026-08-30
- **Source:** `docs/intent/rita.md` § 2; `adr-harvest/cuy/` (16 ADRs); `~/Documents/freeze/cuy`

## Context

`cuy` is a Rails gem frozen at `~/Documents/freeze/cuy`: one author, `main` ahead of a remote
that no longer answers (`localhost:3000`, `cuy/0008`), four unmerged `intent/*` branches, and
docs that disagree with each other about how many archetypes it has (`cuy/0004`). Its ideas are
sound and recorded as 16 ADRs. Its code is a snapshot of a project that stopped mid-thought.
Two ways to use it: `gem "cuy", path:` and inherit the snapshot, or take the ADRs and leave the
code.

## Decision

The kernel is rewritten inside `rita`, from the ADRs in `adr-harvest/cuy/`, as `lib/rita/`.
The frozen source is reference material when an ADR is too thin to implement from — never a
dependency, never a copy-paste base. Where the code is consulted, the gap in the ADR is recorded
as a `rita` decision. Extracting a gem is out of scope; it is a decision for after the kernel
has drawn every `rita` screen.

## Consequences

- `rita` owns its kernel: archetypes and generators answer to `rita`'s screens (ADR 003), not
  to `Pantry` or Clockify.
- The ADRs are extracted, secondhand reads; the rewrite will find places where they are wrong
  or silent. Each is a record here, and a candidate post.
- Bad: the kernel is rebuilt before a single screen exists. The mitigation is order — kernel
  first, `chat` screen immediately after, no other archetype until it is drawn.

## Post seed

- **Angle:** taking a project's decisions and leaving its code — the ADRs as the thing worth
  keeping, the repository as the thing that had expired.
- **Tension:** the pull of `path:` and a working gem in ten minutes, against inheriting a
  snapshot's unresolved branches and doctrine drift as your own.
- **Payoff or cost:** unproven — if the rewrite is faster than the archaeology it replaced,
  the ADRs paid for themselves; if not, this was pride.
