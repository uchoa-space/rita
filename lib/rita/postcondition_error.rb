# frozen_string_literal: true

module Rita
  # A command whose `leaves` clause lied: the body ran, the entity does not answer the
  # declared status. Raised in development and test, logged in production (cuy/0006).
  class PostconditionError < StandardError; end
end
