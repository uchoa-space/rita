require "test_helper"

module Rita
  class ResultTest < ActiveSupport::TestCase
    test "ok carries its data" do
      result = Result.ok(dish: "soup", count: 2)

      assert_predicate result, :ok?
      assert_not_predicate result, :failure?
      assert_nil result.code
      assert_nil result.message
      assert_equal({ dish: "soup", count: 2 }, result.data)
    end

    test "ok with no data has an empty hash" do
      assert_equal({}, Result.ok.data)
    end

    test "failure carries code, data and a nil message by default" do
      result = Result.failure(:too_cheap, floor_cents: 500)

      assert_predicate result, :failure?
      assert_not_predicate result, :ok?
      assert_equal :too_cheap, result.code
      assert_nil result.message
      assert_equal({ floor_cents: 500 }, result.data)
    end

    test "failure keeps an explicit message" do
      result = Result.failure(:handoff, message: "no reliable context")

      assert_equal "no reliable context", result.message
      assert_equal({}, result.data)
    end

    test "failure normalises a string code to a symbol" do
      assert_equal :handoff, Result.failure("handoff").code
    end

    test "a code that cannot be a symbol is a DefinitionError" do
      assert_raises(DefinitionError) { Result.failure(nil) }
      assert_raises(DefinitionError) { Result.failure(42) }
    end

    test "instances and their data are deep-frozen" do
      result = Result.ok(dish: +"soup", items: [ +"a", { note: +"b" } ])

      assert_predicate result, :frozen?
      assert_predicate result.data, :frozen?
      assert_raises(FrozenError) { result.data[:dish] = "stew" }
      assert_raises(FrozenError) { result.data[:dish] << "!" }
      assert_raises(FrozenError) { result.data[:items] << "c" }
      assert_raises(FrozenError) { result.data[:items][0] << "!" }
      assert_raises(FrozenError) { result.data[:items][1][:note] << "!" }
    end

    test "pattern matches the ok branch" do
      dish = case Result.ok(dish: "soup")
      in { ok: true, data: { dish: } } then dish
      in { failure: true } then flunk "matched the failure branch"
      end

      assert_equal "soup", dish
    end

    test "pattern matches the failure branch" do
      code = case Result.failure(:handoff, message: "no reliable context")
      in { ok: true } then flunk "matched the ok branch"
      in { failure: true, code:, message: "no reliable context" } then code
      end

      assert_equal :handoff, code
    end

    test "cannot be built with new" do
      assert_raises(NoMethodError) { Result.new(ok: true, data: {}) }
    end
  end
end
