# frozen_string_literal: true

module Rita
  # ADR 007: a header that cannot be derived from, or a body outside its own `returns`.
  # A bug, raised at boot or on first run; never a domain outcome.
  class DefinitionError < StandardError; end
end
