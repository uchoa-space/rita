require "test_helper"

class EmbedderTest < ActiveSupport::TestCase
  test "embeds to 384 dims, deterministic" do
    a = Embedder.embed("salt the water")
    assert_equal 384, a.size
    assert_equal a, Embedder.embed("salt the water")
  end

  test "embeds a batch, empty batch is empty" do
    assert_equal 2, Embedder.embed_all([ "a", "b" ]).size
    assert_equal [], Embedder.embed_all([])
  end
end
