# frozen_string_literal: true

module Rita
  # A header that cannot be derived from, or a body that stepped outside its own
  # `returns`. Raised at boot or on the first run; never a domain outcome (ADR 007).
  class DefinitionError < StandardError; end
end
