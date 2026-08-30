# ADR 016: Tests are strings, seeds are commands, the registry drives the screen tests

- **Status:** Accepted
- **Date:** 2026-08-30
- **Source:** test review of ADR 003, 004, 005, 009, 010, 013, 015; `adr-harvest/cuy/0007` (HTML strings, no browser), `spaces/003` (recorded fixtures), `spaces/008` (suite runs with no keys), `spaces/009` (one process); `freeze/cuy/docs/use-cases.md` on `Cuy::Seed.plan` ("arrange and act cannot drift apart, because they are the same call"), consulted per ADR 001

## Context

Three testing rules were inherited and scattered: strings not browsers (ADR 003/004), one
process (ADR 005), an injected transport (ADR 005). None says what the test of a use case *is*.
The tests written so far arrange by hand — `create!(status: "approved")` puts an entity in a
state no command produces, so a test can pass for a screen the app cannot reach. "Every screen
renders four states" has one hand-written test for `chat` and no rule that a second archetype
gets the same. The loading state depends on Turbo in a browser nobody has opened. Two ADRs quote
test counts that will rot.

## Decision

**Sizes.** Small: leaves, `Rita::Result`, coercion, the graph — pure Ruby, milliseconds.
Medium: use cases through `Rita.run` against the test database with local embeddings; rungs 2–3
and the `Drafter` through the injected transport. Large: none in the suite. The suite runs with
no API key and no network (`spaces/008`), in one process (`spaces/009`), against
`test/fixtures/corpus`, never the archive.

**Seeds are commands.** For any entity with statuses, the only arrange is
`Rita::Seed.reach(:post, :approved)`: the kernel walks `requires`/`leaves` backwards and runs the
commands that produce the state. A state no command reaches cannot be arranged, which is the
point. Plain `create!` is allowed for entities without a status graph.

**The registry drives the screen tests.** One test enumerates every query whose archetype is
drawn and, for each, renders the four states as strings and asserts the static rules: exactly
one `h1`, `h2` next, no `class=` attribute, the archetype's a11y obligations (`role="log"` +
`aria-live` for `chat`, `<th scope="col">` for `list`, …), a failed state that names its code.
A new archetype or screen enters this test by existing.

**Boot rules run in the suite.** `rita:verify` (graph), `rita:vocabulary` (no raw tags, zero
class selectors in the theme), the contrast audit (ADR 008), the `errors.domain` catalogue
check (ADR 015) and `once:` warnings each have one test that calls them; a rule that only runs
at boot is a rule nobody runs.

**Recorded, not invented.** The first live call to each provider records its raw response under
`test/llm/fixtures/` (keys and ids scrubbed); the parser tests run against those, not against
JSON we wrote ourselves. Until a live call happens the scripted fakes stand and say so.

**The one browser pass** is the Lighthouse run ADR 013 requires, manual, several runs, recorded
in `docs/perf.md` — and it also confirms `turbo-frame[busy]` shows the typing state. No Capybara,
no Selenium, no headless driver in the Gemfile.

**No counts in prose.** An ADR or README quotes a sha, never a run count.

## Consequences

- A test cannot lie about reachability, and a screen cannot skip a state.
- `Rita::Seed` is one more kernel piece with its own small tests; it is also the generator's
  future `rita:seed` for development data.
- Bad: the first `Seed.reach` for `post: :published` will run `Publish` against the tmp blog
  root — which is exactly the test the file write needs.

## Post seed

- **Angle:** letting the state graph, not the test author, decide what a test is allowed to set
  up — so the arrange step stops being where the lies go.
- **Tension:** the convenience of `create!(status:)` against a rule that makes some tests
  impossible to write, on purpose.
- **Payoff or cost:** unproven — the first screen test that fails because no command reaches
  the state it wanted.
