# frozen_string_literal: true

require "test_helper"

module Rita
  class UseCaseTest < ActiveSupport::TestCase
    include TemporaryUseCases

    test "kind, verb and default archetype follow the base class" do
      assert Journal::Write.command?
      assert_equal :post, Journal::Write.verb
      assert_equal :form, Journal::Write.archetype
      assert Journal::Recent.query?
      assert_equal :get, Journal::Recent.verb
      assert_equal :list, Journal::Recent.archetype
    end

    test "the header reads back" do
      assert_equal "Put a note away", Journal::Archive.intent
      assert_equal({ note: Journal::Note }, Journal::Archive.accepts)
      assert_equal({ note: :written }, Journal::Archive.requires)
      assert_equal({ note: :archived }, Journal::Archive.leaves)
      assert_equal({ note: Journal::Note }, Journal::Archive.returns)
      assert_equal %i[recent note_detail], Journal::Archive.invalidates
    end

    test "accepts splits into entities and parameters" do
      assert_equal({ note: Journal::Note }, Journal::Archive.entities)
      assert_equal({ text: String }, Journal::Write.parameters)
      assert_empty Journal::Write.entities
    end

    test "key, namespace and name_key derive from the class name" do
      assert_equal :"journal/note_detail", Journal::NoteDetail.key
      assert_equal :journal, Journal::NoteDetail.namespace
      assert_equal :note_detail, Journal::NoteDetail.name_key
    end

    test "paths derive from entities and archetype" do
      assert_equal "/journal/write", Journal::Write.path
      assert_equal "/journal/recent", Journal::Recent.path
      assert_equal "/journal/notes/:note_id/archive", Journal::Archive.path
      assert_equal "/journal/notes/:note_id", Journal::NoteDetail.path
      assert_equal "/journal/notes/:note_id/archived", Journal::Archived.path
    end

    test "a command creating its one accepted entity nests under the plural" do
      uc = define_use_case("Journal::Adopt", Rita::Command) do
        accepts note: Journal::Note
        leaves note: :written
      end
      assert_equal "/journal/notes/adopt", uc.path
    end

    test "path can be overridden" do
      uc = define_use_case("Journal::Elsewhere", Rita::Query) { path "/somewhere/else" }
      assert_equal "/somewhere/else", uc.path
    end

    test "requires on an entity not in accepts is a DefinitionError" do
      assert_raises(DefinitionError) do
        define_use_case("Journal::Broken", Rita::Command) { requires note: :written }
      end
    end

    test "renders :custom needs a reason and is counted as an escape" do
      assert_raises(DefinitionError) { define_use_case("Journal::Bare", Rita::Query) { renders :custom } }
      assert Journal::Archived.custom?
      assert_match(/struck through/, Journal::Archived.escape_reason)
      assert_not Journal::Recent.custom?
    end

    test "renders carries options" do
      uc = define_use_case("Journal::Thread", Rita::Query) { renders :chat, say: :say }
      assert_equal :chat, uc.archetype
      assert_equal({ say: :say }, uc.render_options)
    end

    test "bodies build results" do
      uc = Journal::Write.new
      assert uc.ok(a: 1).ok?
      assert_equal :nope, uc.failure(:nope).code
    end
  end
end
