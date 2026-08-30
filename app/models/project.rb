# One directory of the corpus (`~/Documents/adr-harvest/<name>`). `knowledge_version` is bumped
# whenever any of its documents change, which is what keeps rungs 0 and 1 from serving stale
# knowledge (spaces/014).
class Project < ApplicationRecord
  has_many :documents, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  # The corpus-wide version an Answer is made at: the sum of every project's bumps, monotonic by
  # construction, so any change anywhere invalidates the caches.
  def self.knowledge_version = sum(:knowledge_version)

  def bump_knowledge_version! = increment!(:knowledge_version)
end
