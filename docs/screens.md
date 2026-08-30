# Screens

What a screen is in `rita`, and the record of the vocabulary that draws it. For the
decisions behind it: ADR 003 (archetypes on demand), 004 (closed vocabulary), 007 (errors
as values), 008 (plain theme), 009 (the `chat` screen).

A screen is never designed. A query declares `renders :<archetype>` and the archetype draws
the query's `returns`; the only thing a screen can vary is the theme. Views are Phlex
leaves from a closed vocabulary; no `class:` attribute and no raw HTML tag exist in `app/`
outside `app/components/` (`test/components/vocabulary_test.rb` holds both rules).

## The vocabulary

Leaves live under `app/components/rita/leaves/` (`Rita::Leaves::*`). Every leaf emits
`data-component`, takes no `**attributes`, and carries its obligations inside itself.

| Leaf | `data-component` | Draws | Obligations |
| :--- | :--- | :--- | :--- |
| `Layout` | `layout`, `masthead`, `brand`, `screen` | the document: head, the one `h1`, `main` | `h1` once; `h2` (Section) is the only level below it; theme stylesheet only, never Tailwind |
| `Thread` | `thread` (in `turbo-frame#thread`), `typing` | the log of messages, `ol#messages`, the typing indicator | `role="log"` `aria-live="polite"` named "Conversation"; `busy:` renders `turbo-frame[busy] aria-busy` |
| `Message` | `message` + `data-role` user/assistant/system; parts `author`, `text`, `sources`, `meta` | one turn; text as paragraphs; a Failure part; Sources; rung/USD/latency | named by role in words (`aria-label`, visible header) — never colour alone; roles closed to three |
| `Sources` | `sources` (part of Message) | the cited documents, title and path, as a named group | `role="group"` named "Sources"; titles only until the corpus screens exist |
| `Composer` | `composer` | labelled textarea + submit for the command named in `say:` | `label[for]`/`id`; targets the thread frame; Stimulus `composer` clears and refocuses after send; Enter sends, Shift+Enter breaks |
| `Actions` | `actions` | a named group, one POST form per command | absent when empty; an unavailable action is absent, never disabled |
| `Section` | `section` | an `h2` and one key of `returns` | named by `aria-labelledby` |
| `Empty` | `empty` | the query's intent and one button per no-keyword command | reuses Actions ("Start") |
| `Failure` | `failure` + `data-code` | `errors.domain.<code>` with the result's scalar data, else the result's message | `role="status"`; rendered where the reader is, never a toast |

Archetypes live under `app/components/rita/archetypes/` (`Rita::Archetypes::*`) and descend
from `Archetypes::Base`, which `reads` keys off `returns`, draws a result (data or failure)
inside `Layout`, and derives actions from the registry: `bare_commands` (no `accepts`) for
the empty state, `actions_on(:entity, record)` for commands acting on one entity whose
`requires` the record satisfies.

## The `chat` archetype

`Chat::Thread` `returns thread:, messages:` and `renders :chat, say: :say`.

```
main[data-component=screen]
  div[data-archetype=chat]
    div[data-region=conversation]   Thread · Empty (when no messages) · Actions · Composer
    div[data-region=context]        one Section per key of `returns` beyond thread/messages
```

One column below 1024px (thread, composer, then sections); two columns above when a context
region exists (`:has([data-region=context])`). Reflow, never hide. The body never scrolls
sideways; every button and field is at least 44px.

### Kernel API

- `Rita::ViewResolver.archetypes` — `{ chat: Rita::Archetypes::Chat }`, set in the
  initializer on every reload.
- `verify_returns!` — at boot: every query's `returns` covers what its archetype `reads`.
- `resolve(use_case, result, busy: false)` — the screen for a query result; `nil` when the
  archetype is not drawn yet (the dispatcher then answers JSON, provisionally — ADR 003).
- `changes_after(command, result)` — `Change(action, target, component)` per Turbo Stream,
  asked of the archetype of every query the command `invalidates`.
- `landing_path(command, result)` — where a command redirects without Turbo: the first
  invalidated query's `path_for(**result.data)`.
- `UseCase.path_for(**entities)` — the derived path with `:<entity>_id` filled.
- `Registry#commands_in(namespace)`.

### The four states

| State | Derived from | Rendered as | Test |
| :--- | :--- | :--- | :--- |
| loading | the composer targets `turbo-frame#thread`, so the frame is busy while `Say` runs | `turbo-frame[busy]` shows `[data-component=typing]` (`role=status`) | `chat_states_test` "loading" (`busy: true`), `vocabulary_test` for the CSS rule |
| empty | `messages` empty | `Empty`: the intent and the Open button; the Composer when a thread exists | `chat_states_test` "empty" ×2, `dispatch_test` root |
| failed | a `Result` failure | query: `Failure` alone in the layout, 422; command over Turbo: a system `Message` carrying `Failure` appended to the log, 422; handoff: an assistant `Message` carrying `Failure` | `chat_states_test` "failed", "handoff"; `dispatch_test` 422 ×3 |
| happy | the messages | the log: every turn named by role, sources, rung/USD/latency | `chat_states_test` "happy", `dispatch_test` Say |

### Streaming

Slice 1 answers the `Say` POST with a Turbo Stream response: two `append`s into
`ol#messages` (the user's turn, the assistant's). No broadcast over Solid Cable yet — one
user, one request, the frame is busy for the whole ladder run, and a broadcast would add a
channel for no reader. When a turn is produced outside the request (a queued rung-3 job),
`changes_after` is the seam a broadcast plugs into.

## Theme

`app/assets/stylesheets/rita.css` (ADR 008): 18 `--rita-*` tokens on `:root`, six of them
background/`on-` pairs, dark by `prefers-color-scheme`, rules keyed to `[data-*]` and
elements only, `prefers-reduced-motion` last. `Rita::Theme.verify!` runs at boot and fails
development and test on a pair below 4.5:1 or on any class selector.
