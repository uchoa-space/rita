# frozen_string_literal: true

module Rita
  # ADR 007: a `leaves` clause that lied — the body ran and the entity does not answer the
  # declared status. A bug in the command, never a domain outcome.
  class PostconditionError < StandardError; end
end
