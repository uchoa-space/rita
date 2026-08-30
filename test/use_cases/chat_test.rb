# frozen_string_literal: true

require "test_helper"

# The two use cases of slice 1 through `Rita.run` — no controller, no browser.
class ChatUseCasesTest < ActiveSupport::TestCase
  include Rendering

  test "Open leaves an open thread and invalidates the thread query" do
    result = Rita.run(Chat::Open)
    assert result.ok?
    assert result.data[:thread].open?
    assert_equal [ Chat::Thread ], Rita.registry.invalidated_by(Chat::Open)
  end

  test "Thread with no thread returns none and no messages; with one, its messages" do
    assert_equal({ thread: nil, messages: [] }, Rita.run(Chat::Thread).data)
    thread = ChatThread.create!
    thread.messages.create!(role: "user", body: "hi")
    result = Rita.run(Chat::Thread, thread: thread.id.to_s)
    assert_equal thread, result.data[:thread]
    assert_equal [ "hi" ], result.data[:messages].map(&:body)
    assert_equal :invalid_argument, Rita.run(Chat::Thread, thread: "0").code
  end

  test "Say writes the user's turn and, on handoff, an assistant turn carrying the failure" do
    thread = ChatThread.create!
    result = Rita.run(Chat::Say, thread: thread, text: "what does spaces say about caching?")
    assert result.ok?, result.to_h.inspect
    message, reply = result.data.values_at(:message, :reply)
    assert_equal %w[user assistant], [ message.role, reply.role ]
    assert reply.failure?
    assert_equal "handoff", reply.failure_code
    assert_equal Ladder::HANDOFF_MESSAGE, reply.failure_message
    assert_equal "handoff", reply.answer.rung
    assert_equal 2, thread.messages.count
  end

  test "Say writes the assistant's turn from a landed answer" do
    thread = ChatThread.create!
    document = a_document
    answer = scalar_answer(cited: [ document.id ])
    landed = Rita::Result.ok(answer: answer, rung: "2", body: "Salt it.", cited_document_ids: [ document.id ],
                             cost_usd: 0.0012, latency_ms: 321)
    result = with_ladder(landed) { Rita.run(Chat::Say, thread: thread, text: "salt?") }
    reply = result.data[:reply]
    assert_equal "Salt it.", reply.body
    assert_equal [ document ], reply.sources
    assert_equal "2", reply.rung
  end

  test "Say refuses blank text as a value, writes nothing, and asks nothing" do
    thread = ChatThread.create!
    result = with_ladder(->(*) { flunk "the ladder must not be asked" }) { Rita.run(Chat::Say, thread: thread, text: "   ") }
    assert_equal :blank, result.code
    assert_equal 0, thread.messages.count
  end

  test "Say is guarded by the thread being open" do
    closed = ChatThread.create!(status: "closed")
    result = Rita.run(Chat::Say, thread: closed, text: "hi")
    assert_equal :guard_failed, result.code
  end

  test "the status graph has no defects" do
    assert_empty Rita::Graph.verify.reject { |d| d.message.include?("journal") }
  end
end
