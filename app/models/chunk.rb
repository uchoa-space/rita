# A `##` section of a Document with its local embedding (spaces/004); the unit of retrieval.
class Chunk < ApplicationRecord
  belongs_to :document

  has_neighbors :embedding

  validates :position, presence: true
  validates :content, presence: true

  # Top-k chunks by cosine for a question vector (spaces/002). Retrieval only ever returns chunks
  # of ingested documents, so any citation outside the returned set is invented by construction
  # (spaces/015).
  def self.retrieve(embedding, limit:)
    nearest_neighbors(:embedding, embedding, distance: "cosine").includes(:document).limit(limit)
  end
end
