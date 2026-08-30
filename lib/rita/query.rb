# frozen_string_literal: true

module Rita
  # Reads; GET; declares the archetype that draws it and the shape it `returns`.
  # A query owns its read and never reuses a shared domain read (ADR 002).
  class Query < UseCase
    def self.kind = :query
  end
end
