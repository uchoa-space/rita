require "test_helper"

class ChatThreadTest < ActiveSupport::TestCase
  test "a new thread is open and answers the kernel's status predicate" do
    thread = ChatThread.create!
    assert thread.open?
    assert_not thread.closed?
    assert Rita::Run.status_satisfied?(thread, :open)
  end

  test "current is the latest open thread, or nil" do
    assert_nil ChatThread.current
    ChatThread.create!(status: "closed")
    first = ChatThread.create!
    second = ChatThread.create!
    assert_equal second, ChatThread.current
    second.update!(status: "closed")
    assert_equal first, ChatThread.current
  end

  test "rita_coerce finds by id and raises ArgumentError otherwise" do
    thread = ChatThread.create!
    assert_equal thread, ChatThread.rita_coerce(thread.id.to_s)
    assert_raises(ArgumentError) { ChatThread.rita_coerce(0) }
  end

  test "messages are ordered by creation" do
    thread = ChatThread.create!
    thread.messages.create!(role: "user", body: "one")
    thread.messages.create!(role: "assistant", body: "two")
    assert_equal %w[one two], thread.messages.map(&:body)
  end
end
