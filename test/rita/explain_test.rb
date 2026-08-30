# frozen_string_literal: true

require "test_helper"

module Rita
  class ExplainTest < ActiveSupport::TestCase
    test "lists every use case, its header, its route and the escapes" do
      report = Explain.report
      assert_includes report, "journal/archive (command)"
      assert_includes report, "  intent      Put a note away"
      assert_includes report, "  requires    note: :written"
      assert_includes report, "  invalidates recent -> journal/recent, note_detail -> journal/note_detail"
      assert_includes report, "  route       POST /journal/notes/:note_id/archive"
      assert_includes report, "  renders     :list"
      assert_includes report, "1 escapes"
      assert_includes report, "  journal/archived renders :custom because"
    end
  end
end
