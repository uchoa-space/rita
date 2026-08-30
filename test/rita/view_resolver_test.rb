# frozen_string_literal: true

require "test_helper"

module Rita
  class ViewResolverTest < ActiveSupport::TestCase
    test "with no archetypes nothing is checked" do
      assert_empty ViewResolver.archetypes
      assert ViewResolver.verify_returns!
    end

    test "a query returning less than its archetype reads fails at boot" do
      ViewResolver.archetypes = { list: Class.new { def self.reads = %i[notes total] } }
      error = assert_raises(DefinitionError) { ViewResolver.verify_returns! }
      assert_match(/journal\/recent renders :list, which reads \[:total\]/, error.message)

      ViewResolver.archetypes = { list: Class.new { def self.reads = [ :notes ] } }
      assert ViewResolver.verify_returns!
    ensure
      ViewResolver.archetypes = {}
    end
  end
end
