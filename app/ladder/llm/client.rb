require "net/http"

module Llm
  # The harness (spaces/003): `complete(system:, user:, json: true)` returns a `Rita::Result` —
  # ok with `text:, input_tokens:, output_tokens:, latency_ms:`, or a failure (`:missing_key`,
  # `:request_failed`) the ladder falls through on (spaces/008). One retry on 429/5xx. The
  # transport is a lambda `(uri, headers, body) -> [status, body]`, injected in tests.
  class Client
    RETRY_STATUSES = [ 429, *500..599 ].freeze

    DEFAULT_TRANSPORT = lambda do |uri, headers, body|
      timeouts = Llm.config.timeouts
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = timeouts[:open]
      http.read_timeout = timeouts[:read]
      response = http.post(uri.path, body, headers)
      [ response.code.to_i, response.body ]
    end

    attr_reader :model

    def initialize(model:, transport: DEFAULT_TRANSPORT)
      @model = model
      @transport = transport
    end

    def complete(system:, user:, json: true)
      key = ENV[key_var].presence
      return Rita::Result.failure(:missing_key, message: "#{key_var} is not set", var: key_var) unless key

      started = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
      status, body = post(headers(key), request_body(system: system, user: user, json: json).to_json)
      return Rita::Result.failure(:request_failed, message: "#{provider} returned #{status}", status: status) unless status == 200

      parsed = JSON.parse(body)
      Rita::Result.ok(text: text_of(parsed, json: json), input_tokens: input_tokens_of(parsed),
                      output_tokens: output_tokens_of(parsed),
                      latency_ms: Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond) - started)
    rescue JSON::ParserError, SystemCallError, IOError, Timeout::Error, OpenSSL::SSL::SSLError => e
      Rita::Result.failure(:request_failed, message: "#{provider}: #{e.class}: #{e.message}")
    end

    private

    def post(headers, body)
      uri = URI(Llm.config.endpoints.fetch(provider))
      status, response = @transport.call(uri, headers, body)
      status, response = @transport.call(uri, headers, body) if RETRY_STATUSES.include?(status)
      [ status, response ]
    end

    def key_var = Llm.config.key_vars.fetch(provider)

    def provider = raise(NotImplementedError)
    def headers(_key) = raise(NotImplementedError)
    def request_body(system:, user:, json:) = raise(NotImplementedError)
    def text_of(_parsed, json:) = raise(NotImplementedError)
    def input_tokens_of(_parsed) = raise(NotImplementedError)
    def output_tokens_of(_parsed) = raise(NotImplementedError)
  end
end
