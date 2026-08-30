# ADR 014: Trust boundaries — model output is data, a slug is a path, a day has a budget, the app is local

- **Status:** Accepted
- **Date:** 2026-08-30
- **Source:** threat model over ADR 000–013 (STRIDE per boundary, OWASP LLM Top 10 2025); `spaces/015` (the citation rule came from a prompt-injection finding), `spaces/001`, `spaces/004`; the blog's `page.mdx` shape (`import … from '@/components/ArticleLayout'`, `export const article`), verified 2026-08-30

## Context

`rita` has five places where untrusted bytes cross into something that acts: corpus text into
prompts, model output into HTML, model output into a **file the Next.js build compiles** (MDX is
JSX — an `import`, an `export` or a JSX tag in a draft body runs at build time), a slug into a
filesystem path, and requests into paid model calls. The ADRs covered the first well (fonts
delimited as data, `cited ⊆ retrieved`) and the others not at all. The app also has no
authentication, which is fine only if it is a decision.

## Decision

| Boundary | Rule |
|---|---|
| model → screen | The `Draft` leaf renders markdown with commonmarker `unsafe: false`: raw HTML dropped, links `http(s)` only, no `javascript:`/`data:` URLs. Everything else the model says is text through Phlex escaping. Model output never reaches `eval`, SQL, a shell, or a path. |
| model → `page.mdx` | The body written by `Publish` is **markdown, never MDX**. Any body line matching `^\s*(import|export)\b` or containing a JSX tag (`<[A-Z][\w.]*`, `{…}` expressions) is `failure(:not_markdown, line:)` — a value, shown in place, never sanitised silently. The JS header of the file is `rita`'s template with the four strings (`author`, `date`, `title`, `description`) JSON-escaped. |
| slug → path | `slug` matches `\A[a-z0-9]+(-[a-z0-9]+)*\z`, at most 80 chars; the target is `File.realpath(blog_root)/src/app/articles/<slug>/page.mdx` and `Publish` refuses if the expanded path is not under that directory or the file exists (`failure(:exists)`). `RITA_BLOG_ROOT` is read once at boot and realpath'd. |
| request → cost | `Say.text` ≤ 4,000 characters (`failure(:too_long)`); a daily USD ceiling in `config/initializers/llm.rb` (default $2) checked against `answers` before any rung-2/3 or `Drafter` call — over it, `failure(:budget)` with the day's total. Drafts ≤ 20 per day. All values, none raise. |
| corpus → prompt | As ADR 005: sources delimited as data, ids cited, `cited ⊆ retrieved`. The corpus is the author's own archive; poisoning is a self-inflicted wound, still caught by the same rule. |
| network → app | **No authentication, by decision, because the app binds `127.0.0.1` only.** `bin/dev`/Puma bind to localhost; `config.hosts` is `localhost`. The day it is exposed — Kamal, a tunnel, `0.0.0.0` — it gets authentication first, not a firewall rule. Rails CSRF stays on for every command. |
| headers | CSP enabled: `default-src 'self'`, scripts by importmap nonce, `style-src 'self'`, no inline script anywhere (ADR 004 makes this free). |
| secrets & logs | Keys from `ENV` only (`spaces/001`), never written; events carry keys, never values (ADR 012); `answers.question` is the one user's own text. |
| supply chain | `Gemfile.lock` committed; `bundle audit` and `brakeman` are part of done (both already in the Gemfile). The embedding model is pinned to a revision and cached (`spaces/004`); no network at request time except the two model clients. |
| publish → public | Unchanged (ADR 006): a human approves in the UI, and the file is the only side effect. |

## Consequences

- Two new failure codes on `Publish` and two on the cost path — all rendered in place (ADR 007).
- Bad: a legitimate post that wants a JSX component (an image, a callout) cannot be published
  by `rita`; the author adds it by hand in the blog repo. Accepted: `rita` writes prose.
- Bad: a $2/day ceiling will be hit on a busy drafting day; raising it is one line and a
  conscious act.

## Post seed

- **Angle:** the file format that made the blog easy to write — MDX — is the one that turns a
  language model's output into build-time code, and nobody had written that down.
- **Tension:** "it's my own machine, my own corpus, my own blog" against five boundaries that
  do not care whose machine it is.
- **Payoff or cost:** unproven — the first `failure(:not_markdown)` a model earns.
