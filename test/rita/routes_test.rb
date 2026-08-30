# frozen_string_literal: true

require "test_helper"

module Rita
  class RoutesTest < ActiveSupport::TestCase
    test "literal segments are drawn before dynamic ones" do
      paths = Routes.ordered(Rita.registry).map(&:path)
      assert paths.index("/journal/write") < paths.index("/journal/notes/:note_id")
      assert paths.index("/journal/notes/:note_id") < paths.index("/journal/notes/:note_id/archive")
    end

    test "every use case is one route on its verb" do
      routes = Rails.application.routes.routes.map { |r| [ r.verb, r.path.spec.to_s.delete_suffix("(.:format)"), r.defaults[:rita_key] ] }
      assert_includes routes, [ "GET", "/journal/recent", "journal/recent" ]
      assert_includes routes, [ "POST", "/journal/notes/:note_id/archive", "journal/archive" ]
      assert_not_includes routes.map { |verb, path, _| [ verb, path ] }, [ "GET", "/journal/write" ]
    end
  end
end
