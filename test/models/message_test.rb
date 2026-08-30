require "test_helper"

class MessageTest < ActiveSupport::TestCase
  setup { @thread = ChatThread.create! }

  test "a message needs a body unless it carries a failure" do
    assert_not @thread.messages.build(role: "assistant").valid?
    assert @thread.messages.build(role: "assistant", failure_code: "handoff", failure_message: "no reliable context").valid?
    assert @thread.messages.build(role: "user", body: "hi").valid?
  end

  test "role is user or assistant" do
    assert_not @thread.messages.build(role: "tool", body: "x").valid?
  end

  test "sources, rung, cost and latency come from the answer" do
    project = Project.create!(name: "alpha")
    document = Document.create!(project: project, path: "alpha/001.md", kind: "adr", title: "ADR 001", body: "b", sha: "s")
    answer = Answer.create!(question: "q", question_embedding: Array.new(384, 0.0), knowledge_version: 0, rung: "2",
                            body: "a", cited_document_ids: [ document.id ], cost_usd: 0.001, latency_ms: 42)
    message = @thread.messages.create!(role: "assistant", body: "a", answer: answer)
    assert_equal [ document ], message.sources
    assert_equal "2", message.rung
    assert_equal 42, message.latency_ms
    assert_in_delta 0.001, message.cost_usd
    assert_empty @thread.messages.create!(role: "user", body: "x").sources
  end
end
