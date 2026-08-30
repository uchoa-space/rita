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

## The rule above the identities: how work enters `main`

> Added 2026-08-30 (`self-contained.md`). Downstream: ADR 017, 020, 021.

- **Outcome:** nothing lands on `main` unreviewed, and the reviewer is a different model than the
  author. One script, `bin/ci`, is what "green" means — locally now, the same steps in Actions
  once a remote exists. There is no CD: deploy is out of scope (`rita.md` § 5), so a pipeline
  after green would automate nothing. A change is one use case, around 300 lines; provisional code
  carries the ADR that owns it and the event that removes it; every debt an ADR admits has one
  home, `docs/owed.md`.
- **Why now:** the first build day put ~4,000 lines on `main` through four agent streams with no
  review, only reconciliation. Seventeen decisions said what good code is and none said who
  checks.
- **Success:** the first `request changes` that catches a tension an ADR named before it lands;
  a review whose Checked section names what it did not check; `bin/ci` printing the ADR beside
  each step.
- **Constraint:** the author replies, the reviewer closes, never the reverse; a review with zero
  `issue` on 300 lines is a finding about the reviewer; "tests pass" alone is a request for
  changes.

### Why I believe this

- **One account cannot satisfy its own review rule, and a rule satisfied only by bypass
  misrepresents the process.** The predecessor project recorded exactly this: GitHub does not let
  a PR's author approve it, so a required-review setting would be opened by hand every merge; it
  chose to drop the setting and keep the discipline on record rather than lie on the settings
  page (`spaces/013`). Apps are the first identity the platform enforces for a persona.
- **A mechanical gate rejected 63 of 69 completion claims in one run, and 7 of 8 in another**
  (`enterprise/0007`, from `groq-harness/0003`). A human reviewing sixty-three false claims in a
  row catches the early ones. That is why the human is the last rung of review and reads the
  review, not the diff.
- **The crew was designed on a self-hosted forge and never ran a single dispatch.** The forge
  outlived its own compose file, restored private keys onto disk on reboot, and was torn down
  (`enterprise/0006`). What survived is the design — a persona is who performed the action,
  recorded where the platform records performers — and the lesson that the bus must be one the
  author does not operate.
- **Whether another model reviewing catches what the same model misses is unmeasured.** The
  blind spots may be shared across models trained alike. The bet is stated in ADR 017's
  Tension to watch; the first review is the test.
