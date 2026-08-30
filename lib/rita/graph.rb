# frozen_string_literal: true

module Rita
  # Walks the `requires`/`leaves` graph and everything derived beside it, and reports
  # structural defects. Trustworthy only because `leaves` is verified, never performed:
  # nothing in the kernel can fake an edge.
  class Graph
    Defect = Struct.new(:type, :message) do
      def to_s = "#{type}: #{message}"
    end

    def self.verify(registry = Rita.registry) = new(registry).verify

    def initialize(registry)
      @registry = registry
    end

    def verify
      unproduced + unconsumed + cycles + path_collisions + dangling_invalidations
    end

    # A status some header requires and no command leaves.
    def unproduced
      required.reject { |entity, status| produced.include?([ entity, status ]) }.map do |entity, status|
        Defect.new(:unproduced, "#{entity}: :#{status} is required by #{requirers(entity, status)} and left by no command")
      end
    end

    # A status some command leaves and no header requires.
    def unconsumed
      produced.reject { |entity, status| required.include?([ entity, status ]) }.map do |entity, status|
        Defect.new(:unconsumed, "#{entity}: :#{status} is left by #{producers(entity, status)} and required by no use case")
      end
    end

    # A status that can reach itself through the commands.
    def cycles
      @registry.entities.flat_map do |entity|
        edges = @registry.transitions_of(entity).filter_map { |from, to, _| [ from, to ] if from }
        statuses = edges.flatten.uniq
        statuses.filter_map do |status|
          Defect.new(:cycle, "#{entity}: :#{status} reaches itself") if reaches?(edges, status, status, [])
        end
      end
    end

    # Two use cases drawing the same verb and path: only the first drawn is reachable.
    def path_collisions
      @registry.group_by { |uc| [ uc.verb, uc.path ] }.select { |_, ucs| ucs.size > 1 }.map do |(verb, path), ucs|
        Defect.new(:path_collision, "#{verb.to_s.upcase} #{path} is derived by #{ucs.map(&:key).join(' and ')}")
      end
    end

    # An `invalidates` naming no query: the promise lands nowhere.
    def dangling_invalidations
      @registry.commands.flat_map do |cmd|
        cmd.invalidates.reject { |short| @registry.resolve_invalidation(cmd, short) }.map do |short|
          Defect.new(:dangling_invalidation, "#{cmd.key} invalidates :#{short}, which names no query")
        end
      end
    end

    private

    def required = @registry.flat_map { |uc| uc.requires.to_a }.uniq

    def produced
      @registry.commands.flat_map { |cmd| cmd.leaves.reject { |e, s| cmd.requires[e] == s }.to_a }.uniq
    end

    def requirers(entity, status) = @registry.select { |uc| uc.requires[entity] == status }.map(&:key).join(", ")
    def producers(entity, status) = @registry.commands.select { |uc| uc.leaves[entity] == status }.map(&:key).join(", ")

    def reaches?(edges, from, target, seen)
      edges.any? do |a, b|
        next false unless a == from
        next true if b == target
        next false if seen.include?(b)

        reaches?(edges, b, target, seen + [ b ])
      end
    end
  end
end
