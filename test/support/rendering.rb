# frozen_string_literal: true

# Renders a Phlex component to a string with a real view context (routes, CSRF, assets),
# and the assertions every leaf test shares. HTML strings only — no browser (cuy/0007).
module Rendering
  def render_html(component)
    controller = ApplicationController.new
    controller.request = ActionDispatch::TestRequest.create
    component.render_in(controller.view_context)
  end

  def assert_no_class_attribute(html)
    assert_no_match(/\sclass=/, html, "a leaf emitted a class attribute")
  end

  # h1 first, then never more than one level deeper than the last, never deeper than h2.
  def assert_heading_order(html)
    levels = html.scan(/<h([1-6])\b/).flatten.map(&:to_i)
    assert_equal 1, levels.first, "the first heading is not h1" if levels.any?
    levels.each_cons(2) { |a, b| assert b <= a + 1, "heading jumps from h#{a} to h#{b}" }
    assert levels.all? { |l| l <= 2 }, "a heading deeper than h2: #{levels.inspect}"
  end

  # Replaces `Ladder.ask` for the block (minitest 6 ships no mock); the ladder is never
  # asked live in the suite, and the keys are unset anyway.
  def with_ladder(answer)
    original = Ladder.method(:ask)
    Ladder.define_singleton_method(:ask) { |*args, **opts| answer.respond_to?(:call) ? answer.call(*args, **opts) : answer }
    yield
  ensure
    Ladder.define_singleton_method(:ask, original)
  end

  def scalar_answer(rung: "2", body: "Salt it.", cited: [])
    Answer.create!(question: "q", question_embedding: Array.new(384, 0.0), knowledge_version: 0, rung: rung,
                   body: body, cited_document_ids: cited, cost_usd: 0.0012, latency_ms: 321)
  end

  def a_document(title: "ADR 001", path: "alpha/001.md")
    project = Project.find_or_create_by!(name: "alpha")
    Document.create!(project: project, path: path, kind: "adr", title: title, body: "b", sha: Document.sha_of(path))
  end
end
