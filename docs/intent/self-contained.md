# Intent: the ADRs justify themselves inside the repository

> **Status: confirmed by interview — 2026-08-30.** Downstream: the five belief intents in this
> directory (`derived-screens`, `errors-as-values`, `cost-ladder`, `trust`, `crew`), the
> `Source:` line of ADR 002–021, and the `Docs: ADR sources` step of `bin/ci`.

- **Outcome:** every conviction the ADRs apply is stated as an intent in `docs/intent/`, with the
  evidence for it written *here* — a number and a sentence — so a reader who has only `rita/`
  can judge an ADR against a belief, not against the author's authority. The external corpora
  (`adr-harvest`, `freeze/*`) remain provenance, never the justification.
- **User:** the reviewing model (`bones`, ADR 017/021). It sees `rita/` and nothing else; a
  `Source:` of `spaces/014` is a citation it cannot open.
- **Why now:** 20 of 21 ADRs justify themselves in `adr-harvest`, `freeze/cuy`, `spaces/*`,
  `enterprise/*`, `clocky`, `inventario`. ADR 017 and 021 then put another model in charge of
  reviewing against those ADRs. The bias is real and the author's; the fix is to declare it
  inside the repo, not to remove it.
- **Success:**
  1. Mechanical — every ADR from 002 to 021, except the three build-derived ones (010, 011, 012),
     names a `docs/intent/*.md` first in its `Source:`; `bin/ci` greps for it.
  2. Behavioural — the first review `bones` writes cites no path under `adr-harvest/`,
     `freeze/` or `spaces/`. If it does, the intent it should have cited is too weak.
- **Constraint:** one intent per belief, never per ADR; each intent short, in the shape of
  `rita.md`; ADRs change only their `Source:` line. Where the author has no number, the belief is
  still written and marked **unmeasured** — the same honesty as ADR 000's "Payoff or cost:
  unproven". A belief left out to hide that it is taste would be the bias this intent exists to
  expose.
- **Out of scope:** internalising the corpus (the archive stays where it is); an intent for
  every ADR; a single "intent of everything"; rewriting any ADR's Context or Decision.

## Marked for review

- **The evidence is summarised by the author of the ADRs.** Five intents written by the same
  hand that wrote twenty-one decisions do not remove the bias. They make it a hypothesis with a
  success criterion, which is the most a single-author repository can do.
- **Three ADRs stay ADR→ADR by decision.** 010, 011, 012 record what the build revealed; their
  justification is the previous ADR and the commit. Forcing them under an intent would be
  cosmetic.
