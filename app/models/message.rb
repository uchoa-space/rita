# One turn of a thread. A user message carries text; an assistant message carries the
# ladder's answer — or, when the ladder handed off, the failure it returned (ADR 007: the
# outcome is a value, and the message is where the reader sees it).
class Message < ApplicationRecord
  ROLES = %w[user assistant].freeze

  belongs_to :thread, class_name: "ChatThread", inverse_of: :messages
  belongs_to :answer, optional: true

  validates :role, inclusion: { in: ROLES }
  validates :body, presence: true, unless: :failure?

  def failure? = failure_code.present?
  def user? = role == "user"
  def assistant? = role == "assistant"

  def sources = answer ? answer.cited_documents.includes(:project).to_a : []
  def rung = answer&.rung
  def cost_usd = answer&.cost_usd
  def latency_ms = answer&.latency_ms
end
