# Intent: model output is data; the app is one person's, local, with a daily budget

> **Status: confirmed by interview — 2026-08-30** (`self-contained.md`). Downstream: ADR 014,
> 019. Provenance: `adr-harvest/spaces/001, 004, 011, 015`, `inventario/0003`; the blog's
> `page.mdx` shape, verified 2026-08-30.

- **Outcome:** whatever a model says is text. It never reaches `eval`, SQL, a shell, a path or
  raw HTML; the body `rita` writes into the blog is markdown, never MDX, and a line that looks
  like JSX or an `import` is a rendered failure, not a sanitised one. A slug is validated before
  it is a path, and the path must resolve under the blog's articles directory. A day has a USD
  ceiling. The app binds `127.0.0.1`, has no authentication *by decision*, and gets
  authentication before any exposure, not a firewall rule. What can be rebuilt (the corpus) and
  what cannot (`answers`, `posts`, threads) are migrated differently; the kernel never imports
  the app; a gem no ADR asks for leaves.
- **User:** the author, alone, on their own machine, with their own archive as the corpus.
- **Why now:** `rita` has five places where untrusted bytes cross into something that acts —
  corpus into prompt, model into HTML, model into a file the Next.js build *compiles*, slug into
  filesystem, request into a paid call. The first was covered by the ladder; the other four by
  nothing until ADR 014.
- **Success:** the four new failure codes (`:not_markdown`, `:exists`, `:too_long`, `:budget`)
  render in place; `bundle audit` and `brakeman` are part of green; a change of embedding model
  cannot make the semantic cache compare vectors from two spaces; `lib/rita/**` has a test that
  it references nothing under `app/`.
- **Constraint:** keys from `ENV` only, never logged; events carry keys, never values; CSP with
  no inline script; the embedding model pinned and cached; the only side effect of publishing is
  one file, after a human click.
- **Out of scope:** multi-user, sessions, roles; deploy of any kind; a WAF or rate limiter in
  front of a localhost app; sanitising MDX into "safe MDX".

## Why I believe this

- **MDX is JSX.** `page.mdx` in the blog opens with `import … from '@/components/ArticleLayout'`
  and `export const article = …`; anything in that file runs at build time. A draft body that
  contains `<Foo>` or `{…}` is code the author did not write, compiled by a build the author
  runs. Verified against the blog's own files 2026-08-30 (ADR 014). No incident — the argument
  is that the build is the attacker's `eval`.
- **Prompt injection through the corpus already produced a MEDIUM finding once,** on the
  predecessor project, with a cache that would have served the poisoned answer to everyone
  (`spaces/015`). The corpus here is the author's own archive; poisoning would be self-inflicted,
  and the rule catches it anyway.
- **A vendor retired a model id mid-build** (`spaces/011`) — which is why ids live in an
  initializer and why a change of embedder must bump `knowledge_version` before the semantic
  cache silently hits wrongly (ADR 019). The silent-wrong-hit failure is **unmeasured**; it is
  reasoned from the cosine of vectors from two different models being meaningless.
- **No auth on localhost is a decision, not an omission.** The failure mode is the day the
  binding changes — a tunnel, `0.0.0.0`, Kamal — and the rule is written for that day. No
  measurement; an argument about which default fails safe.
- **A $2/day ceiling will be hit.** Stated in ADR 014 as an accepted cost: raising it is one
  line and a conscious act. The number is a guess, **unmeasured** until the cost report exists.
- **The Gemfile still carried a browser driver the tests refuse.** `rails new` left `capybara`,
  `selenium-webdriver`, `image_processing`, `kamal`, `thruster`; each one is a supply-chain
  surface for a feature no ADR asked for (ADR 019). Removal is one change each, per ADR 017.
