# Owed (ADR 017)

Every debt an ADR admits, one line each. A change that pays a line deletes it.

| Debt | ADR | Paid when |
|---|---|---|
| `errors.domain.*` catalogue check at boot and in the suite | 007, 015 | the check exists and the suite has a test for it |
| Theme tokens renamed to the Figma set (`background`, `primary`, `line`, …), radius 4/6 | 008 | `rita.css` and `docs/figma.yml` agree |
| `rake evals` with a golden set, τ swept, judge isolated | 005 | first eval table in the repo |
| Recorded provider fixtures under `test/llm/fixtures/` | 016 | first live call to each provider |
| `answers.skips` and the four events with a log subscriber | 012 | the row explains a handoff |
| `once:` header word and `attempts` table | 015 | `Say` and `Draft` declare it |
| `Draft` as a Solid Queue job with broadcast | 011, 013 | no request waits on the large model |
| `Rita::Seed.reach` and the registry-driven four-states test | 016 | `create!(status:)` is gone from tests |
| Boot rules run inside the suite (verify, vocabulary, contrast, catalogue, once) | 016 | one test per rule |
| Lighthouse pass on the happy `chat` screen, numbers in `perf.md` | 013 | the ledger has the row |
| `Journal` sample domain in `test/support` replaced by real use cases as fixtures | 010 | the second real screen exists |
| `corpus_state.embedder` id; bump `knowledge_version` on change | 019 | the column exists and ingest checks it |
| `documents.retired_at`; ingest never deletes | 019 | a removed file leaves a retired row |
| Dependency-rule test: `lib/rita/**` never references `app/` or `Chat::`/`Post::` | 019 | the test exists and passes |
| Remove `capybara`, `selenium-webdriver`, `image_processing`, `kamal`, `thruster`, `tailwindcss-rails` — one change each | 019 | Gemfile carries only what an ADR asks for |
| Mark pre-017 provisional code (`test/support/journal.rb`; drop the stopped Post stream's stash) | 017, 019 | markers present, stash gone |
| First review by bones cites no path under `adr-harvest/`, `freeze/`, `spaces/` | intent self-contained | the review file or PR review reads clean |
| `bin/ci` (audit, importmap audit, brakeman, rubocop, test) printing the ADR per step | 020 | the script exists and reviews cite it |
| `.github/workflows/ci.yml` calls `bin/ci` only: pgvector image, informers cache, no system-test job, no libvips | 020 | the file matches; runs once a remote exists |
| Three GitHub Apps (`scotty`, `bones`, `kirk`) on `uchoa-space`, keys held by the Admiral | 021 | `gh api app` answers for each — **Admiral's gate** |
| `rita` public in `uchoa-space`; `main` protected: `ci` + 1 approval, no force-push/deletion | 020, 021 | settings page matches — **Admiral's gate** |
| `crew` skill on `gh` + installation tokens; bones' skill refuses `APPROVE`; scotty's git identity | 021 | first PR opened by scotty, reviewed by bones, approved by kirk |
