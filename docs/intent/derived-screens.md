# Intent: the header is the spec; the screen is derived

> **Status: confirmed by interview — 2026-08-30** (`self-contained.md`). Downstream: ADR 002,
> 003, 004, 008, 009, 016, 018. Provenance: `adr-harvest/cuy/0002–0007, 0013, 0015`,
> `cuy-kit-tailwind/0001`.

- **Outcome:** a use case is ten declarative lines — `intent`, `accepts`, `requires`, `leaves`,
  `returns`, `invalidates`, `renders` — and everything a screen needs (route, form, guard,
  archetype, stale-ness, the four states) is derived from them at boot. Nobody in `rita` designs a
  screen; they choose an archetype and a return shape. Views are a closed Phlex vocabulary; the
  theme owns every visual decision through `data-*`. The kernel *verifies* postconditions, never
  performs them.
- **User:** the author writing use cases, and the reviewer checking that a screen cannot have
  quietly stopped being derived.
- **Why now:** `rita` has four screens and one author. The category — a data tool for one person
  — is exactly where screens are never designed one at a time, and where a `class:` in a view is
  the first step back to hand-built pages.
- **Success:** `rita:explain` lists every use case and every escape (`renders :custom, because:`);
  the count of escapes stays at zero until a screen genuinely does not fit; two `rita` apps differ
  only in theme; every screen renders loading/empty/failed/happy as HTML strings with no browser.
- **Constraint:** no `class:`, no `**attributes`, no raw tag in `app/` outside components; an
  archetype exists only while a real screen draws it (N ≥ 1) and a header word only when two
  commands need it (N ≥ 2); a leaf has at most the axes the design sidecar names; tests are
  strings, seeds are commands (`Rita::Seed.reach`), so a state no command reaches cannot be
  arranged.
- **Out of scope:** CQRS (no event store, no read model); "one header, N renderers" beyond the
  screen; a design system in the kernel; Capybara or any browser in the suite.

## Why I believe this

- **A screen that can reach for `class:` stops being derived the same afternoon.** The
  predecessor project shipped Material Design 3 in the kernel and reverted it within hours:
  "half a design system is worse than none" — screens were "recognisably Material and
  recognisably worse than a prototype drawn in an afternoon" (`cuy/0005`). A plain, classless
  theme has been the stable state ever since.
- **"By construction" is only true where it is checked.** A Lighthouse pass over three kits, five
  screens, 30 runs (2026-08-22) found the promised 4.5:1 contrast holding in the plain theme and
  breaking in both styled kits — `green-500` fills at 2.21:1, iOS systemGreen at 2.02:1 — and one
  archetype skipping h1 → h3. Cost was fine everywhere (LCP 0.5 s desktop, CLS 0, TBT 0). The
  lesson taken: a guarantee lives in a leaf and is asserted at boot, or it does not exist
  (`cuy/0015`).
- **Seven archetypes drew seven kinds of screen before the project stopped.** The rule "add on
  demand, remove on the last screen" produced a closed set that was never argued about again
  (`cuy/0004`). Whether `chat` generalises is **unmeasured** — `rita` is the first project to
  draw it.
- **A verified postcondition is a test the author cannot forget to write.** `leaves post: :approved`
  checked after `call` catches the command that forgot the transition; a kernel that performed it
  would hide the bug (`cuy/0006`). No measurement — an argument about where bugs surface.
- **Arranging with the command that produces the state cannot drift from the app.**
  `create!(status: "approved")` passed tests for screens the app could not reach; `Seed.reach`
  makes arrange and act the same call. **Unmeasured** in `rita` until the four-states test runs
  from the registry (ADR 016).
