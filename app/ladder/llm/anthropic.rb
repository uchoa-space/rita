module Llm
  # Anthropic Messages API; owns only the request and response shapes. JSON is asked for by
  # prefilling the assistant turn with `{`, which the text is then completed with.
  class Anthropic < Client
    API_VERSION = "2023-06-01"
    JSON_PREFILL = "{"

    private

    def provider = :anthropic

    def headers(key)
      { "x-api-key" => key, "anthropic-version" => API_VERSION, "Content-Type" => "application/json" }
    end

    def request_body(system:, user:, json:)
      messages = [ { role: "user", content: user } ]
      messages << { role: "assistant", content: JSON_PREFILL } if json
      { model: model, max_tokens: Llm.config.max_tokens, temperature: 0, system: system, messages: messages }
    end

    def text_of(parsed, json:)
      text = parsed.fetch("content", []).filter_map { |block| block["text"] if block["type"] == "text" }.join
      json ? JSON_PREFILL + text : text
    end

    def input_tokens_of(parsed) = parsed.dig("usage", "input_tokens").to_i
    def output_tokens_of(parsed) = parsed.dig("usage", "output_tokens").to_i
  end
end
