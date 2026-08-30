# frozen_string_literal: true

module Rita
  # Every use case, its header, what the kernel derived from it, and the count of
  # declared escapes. Inference that cannot be interrogated is the failure mode of this
  # whole design; this is the interrogation.
  class Explain
    def self.report(registry = Rita.registry) = new(registry).report

    def initialize(registry)
      @registry = registry
    end

    def report
      lines = @registry.sort_by { |uc| uc.key.to_s }.flat_map { |uc| explain(uc) + [ "" ] }
      lines << "#{@registry.commands.size} commands, #{@registry.queries.size} queries, #{escapes.size} escapes"
      escapes.each { |uc| lines << "  #{uc.key} renders :custom because #{uc.escape_reason.inspect}" }
      lines.join("\n")
    end

    private

    def escapes = @registry.select(&:custom?)

    def explain(uc)
      lines = [ "#{uc.key} (#{uc.kind})" ]
      lines << "  intent      #{uc.intent}" if uc.intent
      lines << "  accepts     #{shape(uc.accepts)}" if uc.accepts.any?
      lines << "  requires    #{shape(uc.requires)}" if uc.requires.any?
      lines << "  leaves      #{shape(uc.leaves)}" if uc.leaves.any?
      lines << "  returns     #{shape(uc.returns)}" if uc.returns.any?
      lines << "  invalidates #{invalidations(uc)}" if uc.invalidates.any?
      lines << "  renders     :#{uc.archetype}#{options(uc)}" if uc.archetype
      lines << "  route       #{uc.verb.to_s.upcase} #{uc.path}"
    end

    def shape(hash) = hash.map { |k, v| "#{k}: #{v.inspect}" }.join(", ")
    def options(uc) = uc.render_options.map { |k, v| ", #{k}: #{v.inspect}" }.join

    def invalidations(uc)
      uc.invalidates.map do |short|
        target = @registry.resolve_invalidation(uc, short)
        target ? "#{short} -> #{target.key}" : "#{short} -> (no query)"
      end.join(", ")
    end
  end
end
