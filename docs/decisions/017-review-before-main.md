# ADR 017: Nothing lands on `main` unreviewed; the reviewer is another model; provisional code carries its trigger

- **Status:** Accepted
- **Date:** 2026-08-30
- **Source:** `docs/intent/crew.md`; the build day — streams A, B, C and E committed ~4,000 lines to `main` with no review, only reconciliation; `adr-harvest/spaces/010` (commits on `main` until a remote exists), `spaces/013` (one account: review is a discipline on record, not a switch); the author's global review conventions (Conventional Comments; the author replies, the reviewer closes; a review body is Verdict / Checked / Findings)

## Context

Seventeen decisions say what good code is here and none says who checks before it merges. With
agents writing, the author and the reviewer are the same model unless someone decides otherwise,
and the blind spots are shared. The repository has no remote, so there is no pull request to
carry a review. Meanwhile "provisional" things (a JSON fallback, a skipped forgery check, a
sample domain under `test/support`) enter with no owner and leave only when an ADR happens to
notice them; and the debts the ADRs admit — the `errors.domain` boot check, the token rename,
`rake evals`, recorded fixtures — live in five Consequences sections and nowhere a reviewer looks.

## Decision

**Every change is reviewed before it reaches `main`, by a different model than the one that
wrote it.** Until a remote exists the review is a file, `docs/reviews/<short-sha>.md`, with
exactly three sections — Verdict (approve / request changes, one line of why), Checked (scope
covered, and honestly what was not), Findings (numbered, one line each, most severe first, each
labelled `issue|suggestion|question|nitpick` and `blocking|non-blocking`). When a remote and
pull requests exist, the same three sections are the PR review and the file stops. The author
replies; the reviewer closes; the author never resolves their own thread.

**One use case per change.** A screen is a stack — leaf, archetype, use case — of three changes,
not one. Around 300 changed lines is the ceiling for a single logical change; a stream that
delivered more is split before review, not reviewed as a whole.

**Provisional code carries its trigger.** Anything that exists "for now" is marked in the code
with the ADR that owns it and the event that removes it (`# provisional: until ADR 003 draws
the archetype`). A reviewer refuses a "for now" without both.

**Debts have one home.** `docs/owed.md` lists every debt an ADR admits — one line, the ADR, the
trigger that pays it. A change that adds to the list says so in the review; a change that pays a
line deletes it. A reviewer checks the list, not five Consequences sections.

**A consultation is a claim in the diff.** Per ADR 001, code written after reading
`freeze/cuy` says so where it happens (`# after freeze/cuy lib/cuy/graph.rb — cuy/0004 was silent
on cycles`), so the reviewer can check that the ADR gap is recorded (ADR 010) and nothing was
copied.

**One dependency per change**, with its changelog read and the lockfile diff reviewed; the
existing stack first (`Net::HTTP` before any SDK, ADR 005). A dependency added alongside a
feature is two changes.

**Verification is a story, not a checkbox.** The review's Checked section names what ran: the
suite, `rita:verify`, `rita:vocabulary`, the contrast audit, and — for a screen — the string
render of its four states (ADR 016). "Tests pass" alone is a request for changes.

## Consequences

- Reviewing costs one model call per change; the alternative was demonstrated today.
- Bad: `docs/reviews/` will hold files nobody reads once PRs exist. They are history, not
  documentation, and are not migrated.
- Bad: the ~300-line ceiling will be argued every time an agent delivers a stream. The argument
  is the point.

### Tension to watch

The reviewer will start approving because the suite is green and the ADRs are long. The guard
is the Checked section: a review that cannot name what it did not check is not a review, and a
Findings list with zero `issue` entries on 300 lines is a finding about the reviewer.

## Post seed

- **Angle:** a project that wrote seventeen decisions about quality before it wrote the one
  about who enforces them — and found out on the first build day.
- **Tension:** speed of agents committing to `main` against a review gate that makes each
  stream three changes and one more model call.
- **Payoff or cost:** unproven — the first `request changes` that catches a tension from
  ADR 002/009/011 before it lands.
