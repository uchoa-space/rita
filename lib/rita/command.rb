# frozen_string_literal: true

module Rita
  # Mutates; POST; its archetype is `form`, derived from `accepts`, never declared.
  class Command < UseCase
    def self.kind = :command
  end
end
