# frozen_string_literal: true

require "test_helper"

module Rita
  class LeavesTest < ActiveSupport::TestCase
    include Rendering

    LEAVES = [ Leaves::Layout, Leaves::Thread, Leaves::Message, Leaves::Sources, Leaves::Composer,
               Leaves::Actions, Leaves::Section, Leaves::Empty, Leaves::Failure ].freeze

    test "no leaf takes **attributes" do
      LEAVES.each do |leaf|
        kinds = leaf.instance_method(:initialize).parameters.map(&:first)
        assert_not_includes kinds, :keyrest, "#{leaf} takes **attributes"
        assert_not_includes kinds, :rest, "#{leaf} takes *args"
      end
    end

    test "thread is a live log inside its frame, with the typing indicator" do
      html = render_html(Leaves::Thread.new(messages: [ Leaves::Message.new(role: "user", body: "hi") ]))
      assert_match(/<turbo-frame id="thread">/, html)
      assert_match(/<div data-component="thread" role="log" aria-live="polite" aria-label="Conversation">/, html)
      assert_match(/<ol id="messages"><li /, html)
      assert_match(/<p data-component="typing" role="status">Rita is answering…<\/p>/, html)
      assert_no_class_attribute(html)
    end

    test "a busy thread carries busy and aria-busy" do
      html = render_html(Leaves::Thread.new(messages: [], busy: true))
      assert_match(/<turbo-frame id="thread" busy aria-busy="true">/, html)
    end

    test "a message is named by its role in words, with text, meta and sources" do
      document = a_document
      html = render_html(Leaves::Message.new(role: "assistant", body: "One.\n\nTwo.", id: "message-1", sources: [ document ],
                                             rung: "2", cost_usd: 0.0012, latency_ms: 321))
      assert_match(/<li id="message-1" data-component="message" data-role="assistant" aria-label="Rita">/, html)
      assert_match(/<header data-part="author">Rita<\/header>/, html)
      assert_match(%r{<div data-part="text"><p>One.</p><p>Two.</p></div>}, html)
      assert_match(/<p data-part="meta"><span>rung 2<\/span> · <span>\$0.0012<\/span> · <span>321 ms<\/span><\/p>/, html)
      assert_match(/<div data-part="sources" data-component="sources" role="group" aria-label="Sources">/, html)
      assert_match(%r{<cite>ADR 001</cite> — <span>alpha/001.md</span>}, html)
      assert_no_class_attribute(html)
    end

    test "a user message has no meta and no sources" do
      html = render_html(Leaves::Message.new(role: "user", body: "hi"))
      assert_match(/aria-label="You"/, html)
      assert_no_match(/data-part="meta"|data-part="sources"/, html)
      assert_raises(ArgumentError) { Leaves::Message.new(role: "tool", body: "x") }
    end

    test "a message carries a failure part where the reader is" do
      html = render_html(Leaves::Message.new(role: "assistant", failure: Leaves::Failure.new(code: :handoff, message: "no reliable context")))
      assert_match(/<div data-component="failure" data-code="handoff" role="status"><strong>Could not:<\/strong> <span>No reliable context/, html)
    end

    test "the composer is a labelled textarea targeting the thread frame, with focus handled" do
      html = render_html(Leaves::Composer.new(action: "/chat/threads/1/say", label: "Say something"))
      assert_match(/<form method="post" action="\/chat\/threads\/1\/say" id="composer" data-component="composer" data-turbo-frame="thread" data-controller="composer" data-action="turbo:submit-end->composer#reset keydown->composer#keydown">/, html)
      assert_match(/name="authenticity_token"/, html)
      assert_match(/<label for="composer-text">Say something<\/label><textarea id="composer-text" name="text" rows="3" required autofocus data-composer-target="field">/, html)
      assert_match(/<button type="submit">Send<\/button>/, html)
      assert_no_class_attribute(html)
    end

    test "actions is a named group of POST buttons, and absent when empty" do
      html = render_html(Leaves::Actions.new(name: "Thread", actions: [ { label: "Close", path: "/chat/threads/1/close" } ]))
      assert_match(/<nav data-component="actions" aria-label="Thread"><form method="post" action="\/chat\/threads\/1\/close">/, html)
      assert_match(/<button type="submit">Close<\/button>/, html)
      assert_no_match(/disabled/, html)
      assert_equal "", render_html(Leaves::Actions.new(name: "Thread", actions: []))
    end

    test "a section is named by an h2" do
      html = render_html(Leaves::Section.new(name: "Retrieved", id: "retrieved") { "body" })
      assert_match(/<section data-component="section" aria-labelledby="retrieved-heading"><h2 id="retrieved-heading">Retrieved<\/h2>body<\/section>/, html)
    end

    test "empty is the intent and one button per command" do
      html = render_html(Leaves::Empty.new(intent: "Talk it through", actions: [ { label: "Open a thread", path: "/chat/open" } ]))
      assert_match(/<div data-component="empty"><p>Talk it through<\/p><nav data-component="actions" aria-label="Start">/, html)
      assert_match(/action="\/chat\/open"/, html)
    end

    test "failure translates errors.domain.<code> with the result's data, falling back to the message" do
      html = render_html(Leaves::Failure.new(code: :guard_failed, message: "x", data: { entity: :thread, status: :open }))
      assert_match(/thread is not open\./, html)
      html = render_html(Leaves::Failure.new(code: :unknown_code, message: "the message"))
      assert_match(/<span>the message<\/span>/, html)
      html = render_html(Leaves::Failure.new(code: :unknown_code))
      assert_match(/<span>Unknown code<\/span>/, html)
    end

    test "layout has the one h1, the theme stylesheet and no tailwind" do
      html = render_html(Leaves::Layout.new(title: "Rita") { "screen" })
      assert_match(/<h1>Rita<\/h1>/, html)
      assert_match(%r{<main data-component="screen">screen</main>}, html)
      assert_match(/rita[-\w]*\.css/, html)
      assert_no_match(/tailwind/, html)
      assert_heading_order(html)
      assert_no_class_attribute(html)
    end
  end
end
