# One Markdown file of the corpus, idempotent by `sha`; chunked by `##` section into Chunks.
class Document < ApplicationRecord
  KINDS = %w[adr readme note].freeze

  belongs_to :project
  has_many :chunks, -> { order(:position) }, dependent: :destroy

  validates :path, presence: true, uniqueness: true
  validates :kind, inclusion: { in: KINDS }
  validates :title, :body, :sha, presence: true

  def self.sha_of(body) = Digest::SHA256.hexdigest(body)
end
