require "test_helper"
require_relative "env_helper"

class LlmClientTest < ActiveSupport::TestCase
  include EnvHelper

  test "groq: request shape, response shape, key from ENV at call time" do
    calls = []
    transport = lambda do |uri, headers, body|
      calls << [ uri.to_s, headers, JSON.parse(body) ]
      [ 200, { choices: [ { message: { content: "{\"a\":1}" } } ], usage: { prompt_tokens: 10, completion_tokens: 2 } }.to_json ]
    end
    result = with_keys { Llm::Groq.new(model: "m", transport: transport).complete(system: "s", user: "u") }

    assert result.ok?
    assert_equal({ "a" => 1 }, JSON.parse(result.data[:text]))
    assert_equal [ 10, 2 ], result.data.values_at(:input_tokens, :output_tokens)
    uri, headers, body = calls.first
    assert_equal Llm.config.endpoints[:groq], uri
    assert_equal "Bearer g", headers["Authorization"]
    assert_equal "m", body["model"]
    assert_equal [ "system", "user" ], body["messages"].map { |m| m["role"] }
    assert_equal({ "type" => "json_object" }, body["response_format"])
  end

  test "anthropic: request shape with JSON prefill, response text re-prefixed" do
    calls = []
    transport = lambda do |uri, headers, body|
      calls << [ uri.to_s, headers, JSON.parse(body) ]
      [ 200, { content: [ { type: "text", text: "\"a\":1}" } ], usage: { input_tokens: 7, output_tokens: 3 } }.to_json ]
    end
    result = with_keys { Llm::Anthropic.new(model: "m", transport: transport).complete(system: "s", user: "u") }

    assert result.ok?
    assert_equal "{\"a\":1}", result.data[:text]
    assert_equal [ 7, 3 ], result.data.values_at(:input_tokens, :output_tokens)
    _uri, headers, body = calls.first
    assert_equal "a", headers["x-api-key"]
    assert_equal "s", body["system"]
    assert_equal [ "user", "assistant" ], body["messages"].map { |m| m["role"] }
    assert_equal "{", body["messages"].last["content"]
  end

  test "a missing key is a failure naming the variable, without a call" do
    result = with_keys(groq: nil) { Llm::Groq.new(model: "m", transport: ->(*) { flunk }).complete(system: "s", user: "u") }

    assert result.failure?
    assert_equal :missing_key, result.code
    assert_equal "GROQ_API_KEY", result.data[:var]
  end

  test "one retry on 429/5xx, then a failure" do
    statuses = [ 429, 500 ]
    transport = ->(*) { [ statuses.shift, "" ] }
    result = with_keys { Llm::Groq.new(model: "m", transport: transport).complete(system: "s", user: "u") }

    assert_equal :request_failed, result.code
    assert_equal 500, result.data[:status]
    assert_empty statuses
  end

  test "a transport error is a failure, not a raise" do
    transport = ->(*) { raise Errno::ECONNREFUSED }
    result = with_keys { Llm::Groq.new(model: "m", transport: transport).complete(system: "s", user: "u") }

    assert_equal :request_failed, result.code
  end

  test "cost comes from the price table per million tokens" do
    assert_in_delta 0.000105, Llm.cost_usd(RUNG2_MODEL, input_tokens: 1000, output_tokens: 100), 1e-12
    assert_raises(KeyError) { Llm.cost_usd("unpriced", input_tokens: 1, output_tokens: 1) }
  end
end
