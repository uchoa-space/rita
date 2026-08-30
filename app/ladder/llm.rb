# The only place a model is called (spaces/003): two Net::HTTP clients behind one shape.
module Llm
  def self.config = Rails.application.config.x.llm

  # USD for one call, from the price table (per million tokens). An unpriced model is a
  # configuration bug, so `fetch` raises.
  def self.cost_usd(model, input_tokens:, output_tokens:)
    price = config.prices.fetch(model)
    (input_tokens * price[:input] + output_tokens * price[:output]) / 1_000_000.0
  end

  def self.default_clients
    { small: Groq.new(model: config.models[:small]), large: Anthropic.new(model: config.models[:large]) }
  end
end
