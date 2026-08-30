# rita

A conversational CMS: ask a question about a corpus of architecture decision records, get an
answer with its sources and its cost, turn an ADR's *Post seed* into a blog draft, approve it,
and publish it as MDX into the blog repository next door.

## Run

```sh
brew install pgvector            # once; postgresql@17 must be running
bin/setup                        # bundle, db:prepare
bin/rails corpus:ingest          # ~90 s cold; reads ~/Documents/adr-harvest
bin/dev                          # http://localhost:3000
```

Model calls need `GROQ_API_KEY` and `ANTHROPIC_API_KEY` in the shell; without them every
question hands off, which is the designed behaviour (ADR 005).

## Commands

| Command | What it does |
|---|---|
| `bin/rails test` | the suite — strings, one process, no network |
| `bin/rails rita:explain` | every use case, its header, its route, the counted escapes |
| `bin/rails rita:verify` | the status graph: unproduced, unconsumed, cycles, collisions |
| `bin/rails corpus:ingest` | idempotent ingest of the archive |
| `bin/rubocop` · `bundle audit` · `brakeman` | part of done |

## Why it is built this way

`docs/intent/rita.md` says what and why; `docs/decisions/` says why this way, one record per
decision. Start with 001 (the kernel is incubated here, not installed) and 005 (the cost ladder).
