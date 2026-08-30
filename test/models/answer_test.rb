require "test_helper"

class AnswerTest < ActiveSupport::TestCase
  test "rung is one of 0..3 or handoff" do
    answer = Answer.new(question: "q", body: "b", knowledge_version: 0, question_embedding: [ 0.0 ] * 384)
    %w[0 1 2 3 handoff].each { |r| answer.rung = r; assert answer.valid?, r }
    answer.rung = "4"
    assert_not answer.valid?
  end

  test "exact and nearest are scoped to the knowledge version" do
    v = Embedder.embed("how is pasta seasoned?")
    a = Answer.create!(question: "how is pasta seasoned?", body: "salt", knowledge_version: 1, rung: "2", question_embedding: v)

    assert_equal a, Answer.exact("how is pasta seasoned?", version: 1)
    assert_nil Answer.exact("how is pasta seasoned?", version: 2)
    assert_equal a, Answer.nearest(v, version: 1)
    assert_nil Answer.nearest(v, version: 2)
    assert_in_delta 0.0, Answer.nearest(v, version: 1).neighbor_distance, 1e-6
  end
end
