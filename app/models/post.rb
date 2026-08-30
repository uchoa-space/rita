# The declarative header an article derives from (ADR 006): a slug, N source ADRs (N >= 1), and
# the seed — angle, tension, payoff or cost. The draft is derived from it under the editorial
# rules, refined in the thread it was seeded in, and written to the blog only once approved.
# Status moves only through the `Post::*` commands: seed -> drafting -> approved -> published.
class Post < ApplicationRecord
  STATUSES = %w[seed drafting approved published].freeze
  SEED_HEADING = "## Post seed"
  SEED_FIELDS = { "Angle" => :angle, "Tension" => :tension, "Payoff or cost" => :payoff_or_cost }.freeze

  belongs_to :thread, class_name: "ChatThread", inverse_of: :posts
  has_many :post_sources, dependent: :destroy
  has_many :sources, through: :post_sources, source: :document
  has_many :messages, dependent: :nullify

  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  validates :status, inclusion: { in: STATUSES }
  validate :at_least_one_source

  # The kernel's coercion protocol (ADR 010): an unknown id is bad input, an ArgumentError
  # `Rita::Coercion` turns into `failure(:invalid_argument)`.
  def self.rita_coerce(id) = find_by(id: id) || raise(ArgumentError, "no post #{id.inspect}")

  # `013-branch-protection-without-required-reviews.md` -> `branch-protection-without-required-reviews`
  def self.slug_from(path)
    File.basename(path, ".md").sub(/\A\d+-/, "").downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")
  end

  # The three bullets under `## Post seed`, continuation lines joined; a missing field is nil.
  def self.seed_from(body)
    section = body.split(/^## /).find { |s| s.start_with?("Post seed") }.to_s
    bullets = section.lines.drop(1).slice_before { |line| line.start_with?("- ") }.map { |lines| lines.map(&:strip).join(" ") }
    SEED_FIELDS.to_h do |label, field|
      bullet = bullets.find { |b| b.start_with?("- **#{label}:**") }
      [ field, bullet&.delete_prefix("- **#{label}:**")&.strip ]
    end
  end

  STATUSES.each { |s| define_method(:"#{s}?") { status == s } }

  def retrieved_chunks = Chunk.where(id: retrieved_chunk_ids).includes(:document).sort_by { |c| retrieved_chunk_ids.index(c.id) }

  # The message carrying the current draft; actions on a draft belong to the latest one.
  def draft_message = messages.order(:created_at, :id).last

  # The first sentence of the angle, capitalised, or the slug in words.
  def title
    sentence = angle.to_s.split(/(?<=[.!?])\s+/).first.to_s.strip
    sentence.empty? ? slug.tr("-", " ").capitalize : sentence.sub(/\A[a-z]/, &:upcase).chomp(".")
  end

  private

  def at_least_one_source
    errors.add(:sources, "needs at least one document") if sources.empty? && post_sources.empty?
  end
end
