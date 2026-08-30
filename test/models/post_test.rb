require "test_helper"

class PostTest < ActiveSupport::TestCase
  include Rendering

  ADR = Rails.root.join("test/fixtures/files/006-post-header-derives-the-article.md")

  test "slug comes from the filename without its number" do
    assert_equal "branch-protection-without-required-reviews", Post.slug_from("spaces/013-branch-protection-without-required-reviews.md")
    assert_equal "sourdough-starter", Post.slug_from("beta/0002-sourdough-starter.md")
  end

  test "the seed is parsed from the Post seed section, wrapped lines joined" do
    seed = Post.seed_from(ADR.read)
    assert_equal "the CMS that does not own the site — a header, a derivation, and a file written across a directory boundary.", seed[:angle]
    assert_match(/\Athe pull toward a "real" integration .* every success criterion\.\z/, seed[:tension])
    assert_match(/\Aunproven — the first post/, seed[:payoff_or_cost])
    assert_equal({ angle: nil, tension: nil, payoff_or_cost: nil }, Post.seed_from("# ADR\n\n## Context\n\nx"))
  end

  test "a post needs a slug, a thread and at least one source; status has predicates" do
    thread = ChatThread.create!
    post = Post.new(thread: thread, slug: "salted-water")
    assert_not post.valid?
    post.sources << a_document
    assert post.valid?
    post.save!
    assert post.seed?
    assert_not post.drafting?
    assert_not Post.new(thread: thread, slug: "Salted Water", sources: [ a_document(path: "alpha/002.md") ]).valid?
  end

  test "title is the angle's first sentence, else the slug in words" do
    thread = ChatThread.create!
    post = Post.new(thread: thread, slug: "salted-water", angle: "salt early. Everything else follows.")
    assert_equal "Salt early", post.title
    assert_equal "Salted water", Post.new(thread: thread, slug: "salted-water").title
  end
end
