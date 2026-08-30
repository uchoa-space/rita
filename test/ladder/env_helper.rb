# Sets provider keys in ENV for a block and restores them after; keys are read at call time
# (spaces/001), so this is the whole stub for "key present" / "key missing".
module EnvHelper
  def with_keys(groq: "g", anthropic: "a")
    previous = ENV.slice("GROQ_API_KEY", "ANTHROPIC_API_KEY")
    ENV["GROQ_API_KEY"] = groq
    ENV["ANTHROPIC_API_KEY"] = anthropic
    yield
  ensure
    ENV.delete("GROQ_API_KEY")
    ENV.delete("ANTHROPIC_API_KEY")
    ENV.update(previous)
  end
end
