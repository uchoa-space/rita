# frozen_string_literal: true

require "test_helper"

module Rita
  class GraphTest < ActiveSupport::TestCase
    include TemporaryUseCases

    test "the sample domain has no defects" do
      assert_empty Graph.verify
    end

    test "a required status nothing produces" do
      define_use_case("Journal::Burn", Rita::Command) do
        accepts note: Journal::Note
        requires note: :dry
      end
      assert_equal [ :unproduced ], Graph.verify.map(&:type)
      assert_match(/note: :dry is required by journal\/burn/, Graph.verify.first.message)
    end

    test "a produced status nothing consumes" do
      define_use_case("Journal::Soak", Rita::Command) do
        accepts note: Journal::Note
        leaves note: :wet
      end
      assert_equal [ :unconsumed ], Graph.verify.map(&:type)
    end

    test "a cycle" do
      define_use_case("Journal::Reopen", Rita::Command) do
        accepts note: Journal::Note
        requires note: :archived
        leaves note: :written
      end
      defects = Graph.verify.select { |d| d.type == :cycle }
      assert_equal [ "note: :written reaches itself", "note: :archived reaches itself" ], defects.map(&:message)
    end

    test "a path collision" do
      define_use_case("Journal::Elsewhere", Rita::Query) { path "/journal/recent" }
      defect = Graph.verify.find { |d| d.type == :path_collision }
      assert_equal "GET /journal/recent is derived by journal/recent and journal/elsewhere", defect.message
    end

    test "an invalidation naming no query" do
      define_use_case("Journal::Poke", Rita::Command) { invalidates :nowhere }
      defect = Graph.verify.find { |d| d.type == :dangling_invalidation }
      assert_equal "journal/poke invalidates :nowhere, which names no query", defect.message
      assert_equal "dangling_invalidation: #{defect.message}", defect.to_s
    end
  end
end
