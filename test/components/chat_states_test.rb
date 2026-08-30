# frozen_string_literal: true

require "test_helper"

# The four states of `chat` (ADR 003, 009), rendered as strings from the archetype.
module Rita
  class ChatStatesTest < ActiveSupport::TestCase
    include Rendering

    def screen(**options)
      render_html(Archetypes::Chat.new(use_case: Chat::Thread, **options))
    end

    test "the archetype reads what the query returns" do
      assert_equal %i[thread messages], Archetypes::Chat.reads
      assert ViewResolver.verify_returns!
    end

    test "empty with no thread: intent, the Open button, no composer" do
      html = screen(data: { thread: nil, messages: [] })
      assert_match(/<div data-component="empty"><p>Talk a post through with the corpus<\/p>/, html)
      assert_match(/<form method="post" action="\/chat\/open">/, html)
      assert_no_match(/data-component="composer"/, html)
      assert_match(/<ol id="messages"><\/ol>/, html)
      assert_heading_order(html)
      assert_no_class_attribute(html)
    end

    test "empty with an open thread: intent, the Open button and the composer" do
      thread = ChatThread.create!
      html = screen(data: { thread: thread, messages: [] })
      assert_match(/data-component="empty"/, html)
      assert_match(%r{action="/chat/threads/#{thread.id}/say"}, html)
      assert_match(/data-component="composer"/, html)
    end

    test "happy: the log carries every turn named by role, sources and meta" do
      thread = ChatThread.create!
      document = a_document
      thread.messages.create!(role: "user", body: "salt?")
      thread.messages.create!(role: "assistant", body: "Salt it.", answer: scalar_answer(cited: [ document.id ]))
      html = screen(data: { thread: thread, messages: thread.messages.to_a })
      assert_no_match(/data-component="empty"/, html)
      assert_match(/data-role="user" aria-label="You"/, html)
      assert_match(/data-role="assistant" aria-label="Rita"/, html)
      assert_match(/<cite>ADR 001<\/cite>/, html)
      assert_match(/rung 2/, html)
      assert_match(/data-component="composer"/, html)
      assert_heading_order(html)
      assert_no_class_attribute(html)
    end

    test "happy: a handoff turn renders the failure inside the assistant's message" do
      thread = ChatThread.create!
      thread.messages.create!(role: "assistant", failure_code: "handoff", failure_message: "no reliable context")
      html = screen(data: { thread: thread, messages: thread.messages.to_a })
      assert_match(/data-role="assistant" aria-label="Rita"><header data-part="author">Rita<\/header><div data-component="failure" data-code="handoff"/, html)
      assert_match(/No reliable context in the corpus/, html)
    end

    test "loading: the frame is busy and the typing indicator is the status" do
      html = screen(data: { thread: ChatThread.create!, messages: [] }, busy: true)
      assert_match(/<turbo-frame id="thread" busy aria-busy="true">/, html)
      assert_match(/<p data-component="typing" role="status">/, html)
    end

    test "failed: a query failure is the Failure leaf in the layout, nothing else" do
      html = screen(failure: Rita::Result.failure(:invalid_argument, message: "no thread", argument: :thread))
      assert_match(/<div data-component="failure" data-code="invalid_argument" role="status"><strong>Could not:<\/strong> <span>thread was not understood\.<\/span>/, html)
      assert_no_match(/data-component="thread"/, html)
      assert_heading_order(html)
    end

    test "extra returns keys become named sections in the context region" do
      html = screen(data: { thread: nil, messages: [], retrieved: [ a_document ] })
      assert_match(/<div data-region="context"><section data-component="section" aria-labelledby="retrieved-heading"><h2 id="retrieved-heading">Retrieved<\/h2><ul><li>ADR 001<\/li><\/ul><\/section><\/div>/, html)
      assert_heading_order(html)
    end

    test "an action is absent when its requires are unmet, never disabled" do
      closed = ChatThread.create!(status: "closed")
      html = screen(data: { thread: closed, messages: [] })
      assert_no_match(/disabled/, html)
      assert_no_match(/data-component="actions" aria-label="Conversation"/, html)
    end

    test "changes after Say append its turns; after a failure, a system message" do
      thread = ChatThread.create!
      user = thread.messages.create!(role: "user", body: "hi")
      reply = thread.messages.create!(role: "assistant", body: "yo", answer: scalar_answer)
      changes = ViewResolver.changes_after(Chat::Say, Rita::Result.ok(thread: thread, message: user, reply: reply))
      assert_equal [ [ :append, "messages" ] ] * 2, changes.map { |c| [ c.action, c.target ] }
      assert_match(/id="message-#{reply.id}"/, render_html(changes.last.component))

      changes = ViewResolver.changes_after(Chat::Say, Rita::Result.failure(:blank, message: "say something first"))
      assert_equal 1, changes.size
      assert_match(/data-role="system".*data-code="blank"/, render_html(changes.first.component))
    end
  end
end
