# frozen_string_literal: true

module Rita
  # The one place that will know how a use case turns into a screen. Archetypes are not
  # built yet (ADR 003: none until a screen demands it), so this is the seam only:
  # `verify_returns!` will check every query's `returns` against what its archetype
  # `reads`, at boot, once an archetype exists to read anything.
  class ViewResolver
    Defect = Struct.new(:use_case, :message)

    # archetype => the class that draws it. Empty until `chat` lands.
    class << self
      attr_writer :archetypes

      def archetypes = @archetypes ||= {}
    end

    def self.verify_returns!(registry = Rita.registry)
      defects = registry.queries.filter_map do |query|
        archetype = archetypes[query.archetype]
        next unless archetype.respond_to?(:reads)

        missing = archetype.reads - query.returns.keys
        Defect.new(query, "#{query.key} renders :#{query.archetype}, which reads #{missing.inspect} it never returns") if missing.any?
      end
      raise DefinitionError, defects.map(&:message).join("\n") if defects.any?

      true
    end
  end
end
