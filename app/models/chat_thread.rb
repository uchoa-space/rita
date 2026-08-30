# One conversation: the log `chat` draws and `Say` appends to. Named `ChatThread` because
# `::Thread` is Ruby's; the header still calls the entity `thread`.
class ChatThread < ApplicationRecord
  STATUSES = %w[open closed].freeze

  has_many :messages, -> { order(:created_at, :id) }, foreign_key: :thread_id, inverse_of: :thread, dependent: :destroy

  validates :status, inclusion: { in: STATUSES }

  scope :open, -> { where(status: "open") }

  # The thread the root screen shows: the latest open one, or none.
  def self.current = open.order(:created_at).last

  # The kernel's coercion protocol: an unknown id is bad input, raised as ArgumentError
  # for `Rita::Coercion` to turn into `failure(:invalid_argument)`.
  def self.rita_coerce(id) = find_by(id: id) || raise(ArgumentError, "no thread #{id.inspect}")

  def open? = status == "open"
  def closed? = status == "closed"
end
