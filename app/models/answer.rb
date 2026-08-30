# Every answer the ladder lands, with how it was produced: rung, model, tokens, USD, latency and
# the `knowledge_version` it was made at (spaces/014). A handoff writes no row (spaces/007).
class Answer < ApplicationRecord
  RUNGS = %w[0 1 2 3 handoff].freeze

  has_neighbors :question_embedding

  validates :question, :body, presence: true
  validates :rung, inclusion: { in: RUNGS }
  validates :knowledge_version, presence: true

  scope :at_version, ->(version) { where(knowledge_version: version) }

  def self.exact(question, version:)
    at_version(version).where(question: question).order(created_at: :desc).first
  end

  # Nearest previous answer within the same knowledge version; `neighbor_distance` is the cosine
  # distance, so similarity is 1 - distance.
  def self.nearest(embedding, version:)
    at_version(version).nearest_neighbors(:question_embedding, embedding, distance: "cosine").first
  end

  def cited_documents = Document.where(id: cited_document_ids)
end
