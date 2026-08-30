# One directory of the corpus (`~/Documents/adr-harvest/<name>`).
class Project < ApplicationRecord
  has_many :documents, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
