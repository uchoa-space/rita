# Intent: the crew signs on GitHub

> **Status: confirmed by interview — 2026-08-30.** Downstream: ADR 021.

- **Outcome:** the `enterprise` personas get real identities on GitHub, as GitHub Apps in the
  `uchoa-space` organisation. `scotty[bot]` opens pull requests and answers threads.
  `bones[bot]` reviews — Verdict / Checked / Findings, Conventional Comments — and can only
  `COMMENT` or `REQUEST_CHANGES`, never `APPROVE`. `kirk[bot]` approves on his own when bones'
  verdict is approve and `ci` is green, and opens `fix` issues for non-blocking findings accepted
  as deferred. Merge is mechanical after kirk's approval.
- **User:** the author, as Admiral — sets intent at the start and is called only in the written
  exceptions: bones requested changes twice on the same PR; a `question (blocking)` left
  unanswered; a diff touching a security gate (ADR 014: credentials, network exposure, a write
  outside the blog's articles directory).
- **Why now:** `rita` has twenty-one decisions and ADR 017 requires a review by another model
  before `main`; one account cannot approve its own pull request (`spaces/013`). Apps are
  identities the platform enforces; `enterprise` designed the crew and never ran it
  (`enterprise/0006`).
- **Success:** the first `rita` PR opened by scotty, reviewed by bones with at least one
  `issue`, approved by kirk, merged — the Admiral having read the review, not the diff. Branch
  protection satisfied with no bypass.
- **Constraint:** dispatch stays the controller on the author's machine (a skill, the
  terminal); the `enterprise/0003` bridge remains disarmed. `rita` is public in the organisation
  (the Free plan protects branches only on public repositories). The Apps' private keys are the
  Admiral's: created by hand, exported in the shell, never in a repository.
- **Out of scope:** Actions waking agents on labels or comments; spock and uhura; Forgejo;
  auto-merge without kirk's approval; bones approving anything.
