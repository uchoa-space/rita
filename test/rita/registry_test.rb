# frozen_string_literal: true

require "test_helper"

module Rita
  class RegistryTest < ActiveSupport::TestCase
    include TemporaryUseCases

    test "named subclasses register themselves and are found by key" do
      assert_same Journal::Write, Rita.registry[:"journal/write"]
      assert_same Journal::Write, Rita.registry["journal/write"]
      assert_same Journal::Write, Rita.registry[Journal::Write]
      assert_nil Rita.registry[:nowhere]
    end

    test "anonymous subclasses do not register" do
      klass = Class.new(Rita::Query)
      assert_not_includes Rita.registry.to_a, klass
    end

    test "registration dedups by name so a reload replaces" do
      size = Rita.registry.size
      first = define_use_case("Journal::Twice", Rita::Query)
      Rita.registry.unregister(first)
      Object.const_get(:Journal).send(:remove_const, :Twice)
      @temporary_use_cases.clear
      second = define_use_case("Journal::Twice", Rita::Query)
      assert_equal size + 1, Rita.registry.size
      assert_same second, Rita.registry[:"journal/twice"]
    end

    test "commands and queries" do
      assert_includes Rita.registry.commands, Journal::Archive
      assert_includes Rita.registry.queries, Journal::Recent
      assert_not_includes Rita.registry.queries, Journal::Archive
      assert_includes Rita.registry.namespaces, :journal
    end

    test "statuses, transitions and the graph" do
      assert_equal %i[written archived], Rita.registry.statuses_of(:note)
      assert_equal [ [ nil, :written, Journal::Write ], [ :written, :archived, Journal::Archive ] ],
                   Rita.registry.transitions_of(:note)
      assert_equal [ :note ], Rita.registry.entities & [ :note ]
      assert_equal Rita.registry.transitions_of(:note), Rita.registry.graph[:note]
    end

    test "invalidations resolve namespace-local first, then registry-wide" do
      define_use_case("Elsewhere::Recent", Rita::Query)
      assert_same Journal::Recent, Rita.registry.resolve_invalidation(Journal::Write, :recent)

      far = define_use_case("Elsewhere::Ping", Rita::Command) { invalidates :note_detail, :nothing }
      assert_same Journal::NoteDetail, Rita.registry.resolve_invalidation(far, :note_detail)
      assert_nil Rita.registry.resolve_invalidation(far, :nothing)
      assert_equal [ Journal::NoteDetail ], Rita.registry.invalidated_by(far)
      assert_includes Rita.registry.invalidators_of(Journal::Recent), Journal::Archive
    end
  end
end
