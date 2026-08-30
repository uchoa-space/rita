# rita — agent contract (ADR 018)

Read in this order before changing anything: `docs/intent/rita.md`, then the belief intents in `docs/intent/` (`self-contained.md` explains them), `docs/decisions/README.md`
(then the ADRs your change touches), `docs/screens.md`, `docs/owed.md`.

## Rules you will otherwise break

1. A domain outcome is a `Rita::Result`, never a `raise`; a `rescue` in a use-case body is the
   smell (ADR 007). Every `failure(:code)` has an `errors.domain.<code>` row (ADR 015).
2. Views are Phlex leaves under `app/components/rita/leaves/`: no `class:`, no `**attributes`,
   no raw HTML tag anywhere in `app/` outside components; the theme is `rita.css` keyed on
   `data-*` (ADR 004, 008).
3. A command that pays or writes a file declares `once:` (ADR 015). Model output is data: never
   into a path, a shell, raw HTML or MDX (ADR 014).
4. `Ladder.ask` answers questions; `Drafter` writes posts; they share only the HTTP harness
   (ADR 011). No LLM SDK gem — two `Net::HTTP` clients (ADR 005).
5. One dependency per change, changelog read. Nothing lands on `main` unreviewed; the reviewer is
   another model; review goes to `docs/reviews/<sha>.md` until a remote exists (ADR 017).
6. Tests are strings: no browser, no Capybara; arrange with `Rita::Seed.reach`, not
   `create!(status:)`; the suite runs with no API key (ADR 016).

## Reference, not dependency

`~/Documents/freeze/cuy` and `~/Documents/adr-harvest` are read-only. Consult the frozen code
only where an ADR is thin, say so in the diff (`# after freeze/cuy …`), never copy (ADR 001).

## When you decide something

Write `docs/decisions/NNN-slug.md` in the format of ADR 000 (with a Post seed), add it to the
index, and add any admitted debt to `docs/owed.md`. Commits: one line, Conventional Commits,
under 70 chars, no trailers.

## Admiral's gates still open (ADR 021 — remind the author, never do these)

1. Three GitHub Apps on `uchoa-space` — `scotty`, `bones`, `kirk` (permissions in ADR 021),
   private keys under `~/.config/crew/<persona>.pem`, installed on the org.
2. Branch protection on `main`: check `ci` + 1 approval, no force-push/deletion — only after
   `bin/ci` (ADR 020) has run green once.
3. Shell: `CREW_<PERSONA>_APP_ID` and `CREW_<PERSONA>_KEY` for the three personas.

When 1 and 3 exist, the `crew` skill moves to `gh` and the first PR runs scotty → bones → kirk.
Delete this section when `docs/owed.md` no longer lists the three ADR 021 lines.
