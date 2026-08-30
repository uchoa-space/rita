module Llm
  # Groq's OpenAI-compatible chat completions; owns only the request and response shapes.
  class Groq < Client
    private

    def provider = :groq

    def headers(key)
      { "Authorization" => "Bearer #{key}", "Content-Type" => "application/json" }
    end

    def request_body(system:, user:, json:)
      body = { model: model, temperature: 0, max_tokens: Llm.config.max_tokens,
               messages: [ { role: "system", content: system }, { role: "user", content: user } ] }
      body[:response_format] = { type: "json_object" } if json
      body
    end

    def text_of(parsed, json:) = parsed.dig("choices", 0, "message", "content").to_s
    def input_tokens_of(parsed) = parsed.dig("usage", "prompt_tokens").to_i
    def output_tokens_of(parsed) = parsed.dig("usage", "completion_tokens").to_i
  end
end
