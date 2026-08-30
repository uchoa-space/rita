# frozen_string_literal: true

require "test_helper"

module Rita
  class RunTest < ActiveSupport::TestCase
    include TemporaryUseCases

    setup { Journal::Note.reset! }

    test "runs a command by class or by key and returns its Result" do
      result = Rita.run(Journal::Write, text: "hello")
      assert result.ok?
      assert_equal "hello", result.data[:note].text

      result = Rita.run(:"journal/write", text: "again")
      assert_equal 2, result.data[:note].id
    end

    test "an unknown use case is a bug" do
      assert_raises(ArgumentError) { Rita.run(:"journal/nope") }
    end

    test "a failure from the body passes through untouched" do
      result = Rita.run(Journal::Write, text: "  ")
      assert result.failure?
      assert_equal :blank, result.code
      assert_equal "a note needs text", result.message
    end

    test "accepts are coerced: scalars, entities by id, callables" do
      note = Journal::Note.write("one")
      assert_equal [ note ], Rita.run(Journal::Recent, limit: "1").data[:notes]
      assert_same note, Rita.run(Journal::NoteDetail, note: note.id.to_s).data[:note]
      assert_same note, Rita.run(Journal::NoteDetail, note: note).data[:note]

      uc = define_use_case("Journal::Shout", Rita::Query) do
        accepts word: ->(v) { v.to_s.upcase }
        def call(word:) = ok(word: word)
      end
      assert_equal "HI", Rita.run(uc, word: "hi").data[:word]
    end

    test "a value that cannot be coerced is a failure, not a raise" do
      result = Rita.run(Journal::Recent, limit: "ten")
      assert_equal :invalid_argument, result.code
      assert_equal :limit, result.data[:argument]

      result = Rita.run(Journal::NoteDetail, note: 99)
      assert_equal :invalid_argument, result.code
    end

    test "undeclared arguments never reach the body" do
      result = Rita.run(Journal::Write, text: "x", admin: true)
      assert result.ok?
    end

    test "a missing required keyword is a failure" do
      result = Rita.run(Journal::Write)
      assert_equal :missing_argument, result.code
      assert_equal [ :text ], result.data[:missing]
    end

    test "requires is a guard that fails as a value" do
      note = Journal::Note.write("one")
      note.status = :archived
      result = Rita.run(Journal::Archive, note: note)
      assert_equal :guard_failed, result.code
      assert_equal({ entity: :note, status: :written }, result.data)

      assert_equal :guard_failed, Rita.run(Journal::Archive).code
    end

    test "leaves is verified after call, and a lying header raises in test" do
      note = Journal::Note.write("one")
      assert_equal :archived, Rita.run(Journal::Archive, note: note).data[:note].status

      liar = define_use_case("Journal::Liar", Rita::Command) do
        accepts note: Journal::Note
        leaves note: :archived
        def call(note:) = ok(note: note)
      end
      assert_raises(PostconditionError) { Rita.run(liar, note: Journal::Note.write("two")) }
    end

    test "a lying header logs in production" do
      liar = define_use_case("Journal::Liar", Rita::Command) do
        accepts note: Journal::Note
        leaves note: :archived
        def call(note:) = ok(note: note)
      end
      logged = []
      env, logger = Rails.env, Rails.logger
      Rails.env = "production"
      Rails.logger = Struct.new(:lines) { def error(msg) = lines << msg }.new(logged)
      assert Rita.run(liar, note: Journal::Note.write("two")).ok?
      assert_match(/rita.postcondition_failed journal\/liar leaves note: :archived/, logged.first)
    ensure
      Rails.env = env
      Rails.logger = logger
    end

    test "returns is held in both directions on the ok branch" do
      extra = define_use_case("Journal::Extra", Rita::Query) do
        returns a: Integer
        def call = ok(a: 1, b: 2)
      end
      error = assert_raises(DefinitionError) { Rita.run(extra) }
      assert_match(/undeclared \[:b\]/, error.message)

      short = define_use_case("Journal::Short", Rita::Query) do
        returns a: Integer, b: Integer
        def call = ok(a: 1)
      end
      assert_match(/omitted \[:b\]/, assert_raises(DefinitionError) { Rita.run(short) }.message)

      loose = define_use_case("Journal::Loose", Rita::Query) { def call = ok(anything: 1) }
      assert Rita.run(loose).ok?

      failing = define_use_case("Journal::Failing", Rita::Query) do
        returns a: Integer
        def call = failure(:no, why: "not checked")
      end
      assert_equal :no, Rita.run(failing).code
    end

    test "a body that does not return a Result is a bug" do
      wrong = define_use_case("Journal::Wrong", Rita::Query) { def call = { ok: true } }
      assert_raises(DefinitionError) { Rita.run(wrong) }
    end
  end
end
