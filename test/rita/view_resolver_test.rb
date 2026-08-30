# frozen_string_literal: true

require "test_helper"

module Rita
  class ViewResolverTest < ActiveSupport::TestCase
    test "chat is the one archetype drawn, and every query returning what it reads passes" do
      assert_equal({ chat: Rita::Archetypes::Chat }, ViewResolver.archetypes)
      assert ViewResolver.verify_returns!
    end

    test "resolve draws the archetype on ok and on failure, nil when undrawn" do
      assert_nil ViewResolver.resolve(Journal::Recent, Result.ok(notes: []))
      screen = ViewResolver.resolve(Chat::Thread, Result.ok(thread: nil, messages: []))
      assert_kind_of Rita::Archetypes::Chat, screen
      assert_kind_of Rita::Archetypes::Chat, ViewResolver.resolve(Chat::Thread, Result.failure(:invalid_argument))
    end

    test "landing_path fills the invalidated query's path from the result" do
      thread = ChatThread.create!
      assert_equal "/chat/threads/#{thread.id}", ViewResolver.landing_path(Chat::Open, Result.ok(thread: thread))
      assert_equal "/journal/recent", ViewResolver.landing_path(Journal::Write, Result.ok(note: nil))
    end

    test "path_for fills entity ids and leaves the rest" do
      thread = ChatThread.create!
      assert_equal "/chat/threads/#{thread.id}/say", Chat::Say.path_for(thread: thread)
      assert_equal "/chat/threads/:thread_id/say", Chat::Say.path_for
    end

    test "a query returning less than its archetype reads fails at boot" do
      ViewResolver.archetypes = { list: Class.new { def self.reads = %i[notes total] } }
      error = assert_raises(DefinitionError) { ViewResolver.verify_returns! }
      assert_match(/journal\/recent renders :list, which reads \[:total\]/, error.message)

      ViewResolver.archetypes = { list: Class.new { def self.reads = [ :notes ] } }
      assert ViewResolver.verify_returns!
    ensure
      ViewResolver.archetypes = { chat: Rita::Archetypes::Chat }
    end
  end
end
