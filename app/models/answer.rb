# Every answer the ladder produces, with how: rung, rungs tried, model, tokens, USD, latency and
# the corpus-wide `knowledge_version` it was made at (spaces/014). A handoff is a row too
# (`rung: "handoff"`, no body, $0 — ADR 005, adaptation 2); only landed rows feed rungs 0 and 1.
class Answer < ApplicationRecord
  RUNGS = %w[0 1 2 3 handoff].freeze

  has_neighbors :question_embedding

  validates :question, presence: true
  validates :rung, inclusion: { in: RUNGS }
  validates :body, presence: true, unless: :handoff?
  validates :knowledge_version, presence: true

  scope :at_version, ->(version) { where(knowledge_version: version) }
  scope :landed, -> { where.not(rung: "handoff") }

  def self.exact(question, version:)
    landed.at_version(version).where(question: question).order(created_at: :desc).first
  end

  # Nearest previous landed answer within the same knowledge version; `neighbor_distance` is the
  # cosine distance, so similarity is 1 - distance.
  def self.nearest(embedding, version:)
    landed.at_version(version).nearest_neighbors(:question_embedding, embedding, distance: "cosine").first
  end

  def handoff? = rung == "handoff"

  def cited_documents = Document.where(id: cited_document_ids)
end
