# ADR 021: The crew signs as GitHub Apps — bones examines, kirk approves, the Admiral reads reviews

- **Status:** Accepted
- **Date:** 2026-08-30
- **Source:** `docs/intent/crew.md` (confirmed 2026-08-30); `adr-harvest/enterprise/0001` (nothing exists off the bus), `0003` (dispatch guards), `0006` (the forge torn down, never executed), `0007` (attention is rationed, the human is never an approver); `spaces/013` (one account cannot satisfy its own review rule); `claude-skills/0015` (the crew skill is mechanics only), `0016` (identity is carried by the transport, never by prose); the persona definitions in `freeze/enterprise/docs/crew/*.md`; `gh auth status` and `gh api orgs/uchoa-space` verified 2026-08-30 (org exists, Free plan, no repositories)

## Context

ADR 017 says the reviewer is another model and the author never closes their own thread. On a
single GitHub account that is prose, not a rule: the platform sees one user who cannot approve
their own PR, and every merge goes through a bypass — the misrepresentation `spaces/013`
refused to record. `enterprise` solved identity with Forgejo users and a `--login` per action,
then tore the forge down without running a single dispatch. What survives is the design: a
persona is who performed the action, recorded where the platform records performers.

## Decision

**Three GitHub Apps, one per persona, installed on the `uchoa-space` organisation.** Each acts
with its own installation token; the persona is the App, never a name in a body.

| App | Permissions | Does | Never |
|---|---|---|---|
| `scotty` | contents: write, pull_requests: write, issues: write | commits as `scotty` (git identity, not a trailer), opens PRs, replies to threads with evidence at a sha | reviews, approves, resolves its own threads |
| `bones` | pull_requests: write, issues: write, contents: read | reviews with Verdict / Checked / Findings; `REQUEST_CHANGES` or `COMMENT`; closes threads the author answered | `APPROVE` — the permission is granted, the skill refuses the event, and a test in the skill asserts it |
| `kirk` | pull_requests: write, issues: write, contents: write (merge) | `APPROVE` when bones' verdict is approve and `ci` is green; merges; opens `fix` issues for findings accepted as deferred, each naming the PR and the finding | acts when an exception below holds |

**The Admiral is never an approver** (`enterprise/0007`). Kirk decides alone, and reports. The
written exceptions that summon the Admiral, checked by kirk before approving: bones requested
changes twice on the same PR; a `question (blocking)` has no reply; the diff touches a security
gate — a key, a host, a network binding, a write outside `src/app/articles/` (ADR 014). Kirk
then posts what he found and stops; the Admiral answers on the PR.

**Branch protection on `main`:** required check `ci` (ADR 020), one required approval,
no force-push, no deletion. Bones cannot satisfy the approval; only kirk can. `rita` is public
in the organisation because the Free plan protects nothing private (`spaces/013`).

**Dispatch stays on the Admiral's machine.** The `crew` skill moves from `tea --login` to
`gh` with `GH_TOKEN` set to the persona's installation token, minted from a private key the
Admiral holds outside any repository. The `enterprise/0003` bridge — Actions waking agents on
labels — stays disarmed; the guard that matters is kept anyway: one agent per thread at a time,
enforced by the controller, not by a concurrency group.

**Two personas wait.** Spock (conformity) and uhura (outbound) join when a second real PR
needs them — N ≥ 2, the same rule as the header vocabulary (ADR 002).

## Consequences

- ADR 017's `docs/reviews/` files stop the day the first PR exists: the review is on the PR,
  under bones' name, and the approval under kirk's.
- The Admiral's cost per PR is reading one review. The measure of the crew is how often kirk
  summons him — never is a bug, always is a bug.
- Bad: three private keys to keep and rotate; an App token lasts an hour, so the skill mints
  per session. Bad: a public repository before the app has a single screen; accepted, the intent
  is a showcase.
- `owed.md` gains the Apps, the repository, the protection rule, and the skill rewrite.

### Tension to watch

Kirk approving everything because bones approved everything. The guard is in the ledger: a PR
where bones filed zero `issue` and kirk approved is normal once and a finding twice in a row
(ADR 017's tension, now with a name on it). The second guard is the exception list — an
exception that never fires is a rule nobody wrote down.

## Post seed

- **Angle:** the crew a project designed for its own forge, tore down with the forge, and then
  put on the platform it had refused — because the platform enforces the one thing prose
  could not: who you are when you click approve.
- **Tension:** "nothing exists off the bus" against a bus you do not own; the price is three
  private keys and a public repository.
- **Payoff or cost:** unproven — the first PR merged on kirk's approval with no bypass in the
  settings page.
