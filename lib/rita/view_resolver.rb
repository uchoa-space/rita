# frozen_string_literal: true

module Rita
  # The one place that knows how a use case turns into a screen. An archetype is a
  # component class that `reads` keys off a query's `returns` (held at boot by
  # `verify_returns!`), draws the query's result — ok or failure — and, after a command
  # that invalidates its query, says which frames change and with what.
  class ViewResolver
    Defect = Struct.new(:use_case, :message)
    Change = Struct.new(:action, :target, :component)

    class << self
      attr_writer :archetypes

      # archetype => the class that draws it. `chat` is the first (ADR 003).
      def archetypes = @archetypes ||= {}

      def verify_returns!(registry = Rita.registry)
        defects = registry.queries.filter_map do |query|
          archetype = archetypes[query.archetype]
          next unless archetype.respond_to?(:reads)

          missing = archetype.reads - query.returns.keys
          Defect.new(query, "#{query.key} renders :#{query.archetype}, which reads #{missing.inspect} it never returns") if missing.any?
        end
        raise DefinitionError, defects.map(&:message).join("\n") if defects.any?

        true
      end

      # The screen for a query's result, or nil when its archetype is not drawn yet.
      def resolve(use_case, result, busy: false)
        archetype = archetypes[use_case.archetype]
        return unless archetype

        if result.ok?
          archetype.new(use_case: use_case, data: result.data, busy: busy)
        else
          archetype.new(use_case: use_case, failure: result)
        end
      end

      # The frames a command's result changes on the screens it invalidates: one
      # `Change` per Turbo Stream action, asked of each invalidated query's archetype.
      def changes_after(command, result, registry: Rita.registry)
        registry.invalidated_by(command).flat_map do |query|
          archetype = archetypes[query.archetype]
          next [] unless archetype.respond_to?(:changes_after)

          archetype.changes_after(query, command, result)
        end
      end

      # Where a command lands without Turbo: the first query it invalidates, with the
      # entities the result carries filling its path; the root when there is none.
      def landing_path(command, result, registry: Rita.registry)
        query = registry.invalidated_by(command).first
        return "/" unless query

        query.path_for(**result.data)
      end
    end
  end
end
