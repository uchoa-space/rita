# Intent: rita

> **Status: confirmed by interview — 2026-08-30.** Supersedes the 2026-08-29 draft
> (`~/Desktop/intent.md`), which was written by another model and treated `cuy` as an installed
> dependency with archetypes it does not have. Nothing in the product intent changed; the
> architecture section was corrected against the ADRs in `~/Documents/adr-harvest/cuy/`.

## 1. Statement of intent

- **Outcome:** `rita` is a conversational CMS in Rails. A chat request ("a post about branch
  protection that only works with bypass") runs a retrieval ladder over the `adr-harvest` corpus,
  assembles a declarative `Post` header (N ADRs as sources, N ≥ 1), generates an MDX draft from
  the ADRs' *Post seeds*, is refined in the same conversation, and on explicit approval writes the
  file to `~/Documents/uchoa-space/src/app/articles/<slug>/page.mdx`.
- **User:** the author, alone. Personal operation with minimal effort; a technical portfolio
  piece; and meta-circular — building `rita` and the blog feeds future posts.
- **Why now:** the corpus is fully audited (~460 ADRs with seeds and provenance, 94 project
  READMEs with Notes). The `uchoa-space` blog (Next.js 16, Tailwind Plus Spotlight) is built and
  has zero posts. `rita` automates the cross-referencing and the drafting.
- **Success:**
  1. A chat request returns, in seconds, a coherent MDX draft that crosses its sources — e.g.
     `spaces/013`, `spaces/010` and the `spaces/README.md` Notes for the branch-protection post.
  2. Tone and sources are refined from the chat, not from a form.
  3. Publishing is one click and the blog renders it immediately (local `next dev`).
  4. Every generated answer carries its rung, cost in USD and latency.
- **Constraint:** the ladder is replicated from `spaces/014` and `spaces/015` (adaptations in ADR 005). Everything
  runs locally.
- **Out of scope:** see § 5.

## 2. Architecture: `cuy` is incubated here, not installed

`cuy` is a concept and a set of ADRs, not a gem `rita` depends on. The kernel is **rewritten from
scratch inside this repository, from the ADRs** in `~/Documents/adr-harvest/cuy/`. The frozen
source at `~/Documents/freeze/cuy` is reference material when an ADR is vague — never a
dependency, never a copy-paste base. If the kernel proves itself in `rita`, extracting it as a
gem is a later decision; it is not this project's goal.

### 2.1 What is kept (the base)

| Principle | Source ADR | In `rita` |
| :--- | :--- | :--- |
| Command/query separation at the use-case boundary — explicitly **not** CQRS | `cuy/0002` | `Command` and `Query` classes with a declarative header: `intent`, `accepts`, `requires`, `leaves`, `returns`, `invalidates`, `renders` |
| Closed Phlex leaf vocabulary, no utility-class CSS in app code | `cuy/0003` | Phlex components; the theme owns the CSS, keyed by `data-*` |
| The header is the spec; the screen is derived from archetype + return shape | `cuy/0004` | routes, forms, guards and views derived at boot |
| Postconditions (`leaves`) are verified, never performed, by the kernel | `cuy/0006` | same |
| Integration tests against rendered HTML strings, no browser | `cuy/0007` | same |
| Escapes are declared and counted (`renders :custom, because: "…"`) | `cuy/0004` | `rita:explain` counts them |

### 2.2 What is decided by `rita`

Archetypes and generators exist because a `rita` screen demands them — the same rule the ADRs
state. `cuy`'s seven (`list`, `detail`, `form`, `overview`, `compose`, `board`, `report`) are the
candidate vocabulary, not a requirement; `rita` adds and omits as its screens dictate.

| Screen | Archetype | Header |
| :--- | :--- | :--- |
| **Conversation** — the main surface: thread + composer, inline draft preview with actions; sidebar with the current `Post` header and the retrieved chunks | `chat` — **new**. `rita` is the real screen that demands it (`freeze/cuy/docs/intent/chat.md` was a draft waiting for exactly this) | `Query Thread` → `renders :chat, say: :say`; `Command Say` → `invalidates :thread` |
| **Posts** — pipeline of `Post` headers: Seeds → Drafting → Published | `board` | status graph from `requires`/`leaves` |
| **Corpus** — the 94 projects and ~460 ADRs, vector search | `list` + `detail` (`ref` is a field type, not an archetype — `cuy/0013`) | |
| **Costs** — rung distribution, USD spent, cache hit rate | `report` | |

Self-updating screens (`live`) are a kernel concept (Turbo Stream broadcast), a prerequisite of
`chat` streaming, not a screen.

### 2.3 The `Post` header

A `Post` is the declaration the article derives from — the `UseCase` pattern applied to writing:

- **Sources:** N ADRs (N ≥ 1); default is one, per `adr-harvest/CLAUDE.md` § *Writing the posts*.
- **Fields:** `slug`, `angle` (thesis), `tension` (the fork the reader must feel),
  `payoff_or_cost` (the ending — often a cost, or an outcome never observed).
- **Derivation:** the MDX draft applies the editorial rules of `adr-harvest/CLAUDE.md` § *Writing
  the posts* to the seeds plus retrieved context. Context/Decision/Consequences are the record;
  a post that paraphrases them in order is a changelog, and fails.

### 2.4 RAG with a cost ladder (from `spaces`)

Replicates `spaces/014` ("the ladder is the product") and `spaces/015` (citation rule):

| Rung | Mechanism | Cost |
| :--- | :--- | :--- |
| 0 — exact cache | exact match on question within the same `knowledge_version` | $0 |
| 1 — semantic cache | local ONNX `all-MiniLM-L6-v2` via `informers`, `vector(384)` in pgvector, cosine τ ≥ 0.90 | $0 |
| 2 — small model | Groq, cheapest model that cites (`spaces/011` used `openai/gpt-oss-20b`) | metered |
| 3 — large model | Anthropic, larger model (`spaces/011` used Sonnet 4.5) | metered |
| handoff | "no reliable context" — a rung, never a 500, never an unsourced answer (`spaces/007`) | $0 |

Rungs 2 and 3 accept an answer only if `cited ⊆ retrieved`; a citation outside the retrieved set
misses the rung (`spaces/015`). Model ids live in an initializer, never in code (`spaces/011`);
API keys come from the environment, a missing key falls through to the next rung (`spaces/001`,
`spaces/008`). No judge runs inside a request (`spaces/005`).

## 3. Repositories

| Repository | Stack | Role |
| :--- | :--- | :--- |
| `~/Documents/rita` | Rails 8.1, Postgres 17 + pgvector, `informers` (ONNX), Phlex, Turbo, Solid Queue | CMS, incubated kernel, ladder, chat, MDX writer |
| `~/Documents/uchoa-space` | Next.js 16, Tailwind Plus Spotlight | public blog; receives MDX under `src/app/articles/<slug>/page.mdx` |
| `~/Documents/adr-harvest` | Markdown, read-only | primary corpus: ADRs, READMEs, Notes |
| `~/Documents/freeze/cuy` | frozen Rails gem | reference only |

## 4. Marked for review

- **Model ids per rung.** The 2026-08-29 draft pinned `claude-sonnet-4-5`. This doc pins nothing:
  the ids are configuration and will be chosen at implementation against current pricing, the way
  `spaces/011` did.
- **"One header, N renderers" (`cuy/0014`)** is *Proposed*, not accepted. The previous draft treated
  it as settled. `rita` derives one renderer (the screen) and takes no position on the rest.
- **Rewriting the kernel from ADRs, not code,** is a deliberate cost: the ADRs are extracted,
  secondhand reads (`adr-harvest/CLAUDE.md` § *Writing the posts*). Where an ADR is too thin to
  implement from, the frozen source is consulted and the gap is recorded as a `rita` ADR.

## 5. Out of scope

- Production deploy of either project — local only.
- Publishing without an explicit approval action in the UI.
- Modifying `uchoa-space` beyond writing MDX files into `src/app/articles/`.
- Extracting the kernel as a gem, or resurrecting `freeze/cuy`.
- Figma, design plugins, or any external design integration.
- The other renderers of `cuy/0014` (MCP, email, chat transports, SMS).
