require "test_helper"
require_relative "env_helper"

class LadderTest < ActiveSupport::TestCase
  include EnvHelper

  QUESTION = "how should pasta water be seasoned?"

  setup do
    Corpus::Ingest.call(Rails.root.join("test/fixtures/corpus"))
    @salt_chunk = Chunk.joins(:document).find_by!(documents: { path: "alpha/001-salted-water.md" }, position: 2)
  end

  # A transport that answers every call with a Groq-shaped 200 citing the given ids.
  def groq_transport(cited:, answer: "Salt the water generously.", status: 200)
    lambda do |_uri, _headers, _body|
      content = { answer: answer, cited: cited }.to_json
      [ status, { choices: [ { message: { content: content } } ],
                  usage: { prompt_tokens: 1000, completion_tokens: 100 } }.to_json ]
    end
  end

  def anthropic_transport(cited:, answer: "Salt it well.")
    lambda do |_uri, _headers, _body|
      text = { answer: answer, cited: cited }.to_json.delete_prefix("{")
      [ 200, { content: [ { type: "text", text: text } ], usage: { input_tokens: 2000, output_tokens: 50 } }.to_json ]
    end
  end

  def clients(small: nil, large: nil)
    { small: Llm::Groq.new(model: RUNG2_MODEL, transport: small || ->(*) { flunk "rung 2 must not be called" }),
      large: Llm::Anthropic.new(model: RUNG3_MODEL, transport: large || ->(*) { flunk "rung 3 must not be called" }) }
  end

  test "rung 2 lands when cited is within retrieved, and records cost" do
    result = with_keys { Ladder.ask(QUESTION, clients: clients(small: groq_transport(cited: [ @salt_chunk.id ]))) }

    assert result.ok?
    assert_equal "2", result.data[:rung]
    assert_equal "Salt the water generously.", result.data[:body]
    assert_equal [ @salt_chunk.document_id ], result.data[:cited_document_ids]
    assert_in_delta 0.000105, result.data[:cost_usd].to_f, 1e-9
    answer = result.data[:answer]
    assert_equal RUNG2_MODEL, answer.model
    assert_equal %w[0 1 2], answer.rungs_tried
    assert_equal Corpus.knowledge_version, answer.knowledge_version
    assert answer.latency_ms >= 0
  end

  test "rung 2 misses on a citation outside the retrieved set; rung 3 lands" do
    invented = Chunk.maximum(:id) + 1000
    result = with_keys do
      Ladder.ask(QUESTION, clients: clients(small: groq_transport(cited: [ @salt_chunk.id, invented ]),
                                            large: anthropic_transport(cited: [ @salt_chunk.id ])))
    end

    assert result.ok?
    assert_equal "3", result.data[:rung]
    assert_equal "Salt it well.", result.data[:body]
    assert_equal RUNG3_MODEL, result.data[:answer].model
    assert_in_delta 0.00675, result.data[:cost_usd].to_f, 1e-9
  end

  test "rung 0 serves an exact repeat at the same knowledge_version for free" do
    with_keys { Ladder.ask(QUESTION, clients: clients(small: groq_transport(cited: [ @salt_chunk.id ]))) }

    result = Ladder.ask(QUESTION, clients: clients)

    assert_equal "0", result.data[:rung]
    assert_equal "Salt the water generously.", result.data[:body]
    assert_equal 0, result.data[:cost_usd]
    assert_equal 2, Answer.count
    assert_equal %w[0], result.data[:answer].rungs_tried
  end

  test "rung 1 serves a close rewording; a loose one pays rung 2" do
    with_keys { Ladder.ask(QUESTION, clients: clients(small: groq_transport(cited: [ @salt_chunk.id ]))) }

    close = Ladder.ask("how should the pasta water be seasoned?", clients: clients)
    assert_equal "1", close.data[:rung]
    assert_equal "Salt the water generously.", close.data[:body]

    loose = with_keys { Ladder.ask("what goes in the pot before the spaghetti?", clients: clients(small: groq_transport(cited: [ @salt_chunk.id ], answer: "Salt."))) }
    assert_equal "2", loose.data[:rung]
  end

  test "a knowledge_version bump invalidates both caches" do
    with_keys { Ladder.ask(QUESTION, clients: clients(small: groq_transport(cited: [ @salt_chunk.id ]))) }
    Corpus::State.bump_knowledge_version!

    result = with_keys { Ladder.ask(QUESTION, clients: clients(small: groq_transport(cited: [ @salt_chunk.id ], answer: "Fresh."))) }

    assert_equal "2", result.data[:rung]
    assert_equal "Fresh.", result.data[:body]
  end

  test "missing keys fall through to a handoff that writes a row and never raises" do
    result = with_keys(groq: nil, anthropic: nil) do
      Ladder.ask(QUESTION, clients: clients(small: ->(*) { flunk "no key, no call" }, large: ->(*) { flunk "no key, no call" }))
    end

    assert result.failure?
    assert_equal :handoff, result.code
    assert_equal "no reliable context", result.message
    assert_equal %w[0 1 2 3], result.data[:rungs_tried]
    assert_includes result.data[:retrieved], @salt_chunk.id
    handoff = result.data[:answer]
    assert_equal "handoff", handoff.rung
    assert_nil handoff.body
    assert_equal 0, handoff.cost_usd
    assert_equal 1, Answer.count
  end

  test "a failed provider request and an empty citation both miss the rung" do
    down = ->(*) { [ 503, "down" ] }
    result = with_keys { Ladder.ask(QUESTION, clients: clients(small: down, large: anthropic_transport(cited: []))) }

    assert_equal :handoff, result.code
  end

  test "malformed JSON misses the rung" do
    garbage = ->(*) { [ 200, { choices: [ { message: { content: "not json" } } ], usage: {} }.to_json ] }
    result = with_keys(anthropic: nil) { Ladder.ask(QUESTION, clients: clients(small: garbage)) }

    assert_equal :handoff, result.code
  end

  test "an empty corpus hands off without calling a model" do
    Chunk.delete_all
    result = with_keys { Ladder.ask(QUESTION, clients: clients) }

    assert_equal :handoff, result.code
    assert_equal [], result.data[:retrieved]
  end
end
