# Model ids, key variable names, prices and ladder thresholds live here, never in code
# (spaces/011): a model swap is one line plus a price row. Keys are read from ENV at call time
# and never stored (spaces/001); a missing key falls through to the next rung (spaces/008).
#
# Rung 3's id is a placeholder inherited from spaces/011's one measured run; it is chosen against
# current pricing at go-live, with `rake evals` (deferred, ADR 005) as the acceptance rule:
# accept a swap only if grounded rises by more than $/answer does.
RUNG2_MODEL = "openai/gpt-oss-20b"
RUNG3_MODEL = "claude-sonnet-4-5"

Rails.application.config.x.llm.models = { small: RUNG2_MODEL, large: RUNG3_MODEL }
Rails.application.config.x.llm.key_vars = { groq: "GROQ_API_KEY", anthropic: "ANTHROPIC_API_KEY" }
Rails.application.config.x.llm.endpoints = {
  groq: "https://api.groq.com/openai/v1/chat/completions",
  anthropic: "https://api.anthropic.com/v1/messages"
}
# USD per million tokens, input / output, as listed by each vendor on the date noted.
Rails.application.config.x.llm.prices = {
  RUNG2_MODEL => { input: 0.075, output: 0.30, as_of: "2026-08-26 (spaces/011)" },
  RUNG3_MODEL => { input: 3.0, output: 15.0, as_of: "2026-08-26 (spaces/011)" }
}
# Request path only; there is no judge in a request (spaces/005), so no 60 s read timeout here.
Rails.application.config.x.llm.timeouts = { open: 5, read: 20 }
Rails.application.config.x.llm.max_tokens = 1024

Rails.application.config.x.ladder.semantic_tau = 0.90
Rails.application.config.x.ladder.top_k = 8

# The first request after boot would otherwise pay the model load (spaces/004).
Rails.application.config.after_initialize { Embedder.load! if Rails.env.production? }
