# ADR 006: The `Post` header derives the article; MDX is written into `uchoa-space` only on approval

- **Status:** Accepted
- **Date:** 2026-08-30
- **Source:** `adr-harvest/CLAUDE.md` § "Writing the posts"; `docs/intent/rita.md` § 1, 2.3, 5

## Context

The corpus has one downstream product: posts in `~/Documents/uchoa-space/src/app/articles/
<slug>/page.mdx`. The editorial rule is already written: the Post seed is the outline, not the
ADR; a post that paraphrases Context/Decision/Consequences in order is a changelog; go back to
the source before writing. Two ways to get MDX into the blog: a publishing API or CMS
integration on the Next.js side, or writing the file.

## Decision

A `Post` is a declarative header, the `UseCase` pattern applied to writing: `slug`, `sources`
(N ADRs, N ≥ 1, default 1), `angle`, `tension`, `payoff_or_cost`. The draft is derived from the
header plus retrieved chunks under the editorial rules above, and refined in the chat. The
`Publish` command writes the MDX file straight into the blog repository and nowhere else;
`requires post: :approved` guards it, and approval is a human action in the UI. `uchoa-space`
is not modified beyond receiving files. The body is markdown, never MDX; the slug is validated
as a path segment; the write is confined to the articles directory (ADR 014).

## Consequences

- The blog stays a static Next.js site with no knowledge of `rita`; the coupling is a path and
  a file shape. The MDX template lives in one file and a fixture copied from a real article in
  the blog is the contract a test pins; when the blog's `ArticleLayout` changes, the fixture is
  re-copied and the test says what moved.
- The `Post` board's columns (Seed → Drafting → Published) are the `requires`/`leaves` graph of
  the `Post` commands (ADR 022), not a status enum designed for the screen.
- Bad: "write a file into another repo" has no rollback but `git` in that repo. Acceptable
  because the human approved and both repos are local.

## Post seed

- **Angle:** the CMS that does not own the site — a header, a derivation, and a file written
  across a directory boundary.
- **Tension:** the pull toward a "real" integration (API, webhook, preview deploy) against a
  `File.write` that already satisfies every success criterion.
- **Payoff or cost:** unproven — the first post the blog renders from a `rita`-written file.
