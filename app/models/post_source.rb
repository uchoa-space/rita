# One row of the N >= 1 documents a Post derives from.
class PostSource < ApplicationRecord
  belongs_to :post
  belongs_to :document
end
