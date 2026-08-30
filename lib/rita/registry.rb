# frozen_string_literal: true

module Rita
  # Every named subclass of Command or Query registers itself here. Deduplication is by
  # name, not identity: a development reload redefines the class and must replace, not
  # double. Answers the questions every derived thing asks.
  class Registry
    include Enumerable

    def initialize
      @use_cases = []
    end

    def register(use_case)
      @use_cases.reject! { |uc| uc.name == use_case.name }
      @use_cases << use_case
      @index = nil
      use_case
    end

    def unregister(use_case)
      @use_cases.reject! { |uc| uc.name == use_case.name }
      @index = nil
    end

    def clear!
      @use_cases.clear
      @index = nil
    end

    def each(&) = @use_cases.each(&)
    def size = @use_cases.size
    def commands = select(&:command?)
    def queries = select(&:query?)
    def namespaces = filter_map(&:namespace).uniq
    def commands_in(namespace) = commands.select { |cmd| cmd.namespace == namespace&.to_sym }

    # `registry[:"notes/write"]`, `registry["notes/write"]` or `registry[Notes::Write]`.
    def [](key)
      key = key.key if key.is_a?(Class)
      index[key.to_s]
    end

    # Every entity some header requires or leaves.
    def entities
      flat_map { |uc| uc.requires.keys + uc.leaves.keys }.uniq
    end

    # Every status an entity is required or left in, across the registry.
    def statuses_of(entity)
      entity = entity.to_sym
      flat_map { |uc| [ uc.requires[entity], uc.leaves[entity] ] }.compact.uniq
    end

    # `[from, to, command]` for every command that moves the entity; `from` is nil when
    # the command creates it.
    def transitions_of(entity)
      entity = entity.to_sym
      commands.filter_map do |cmd|
        to = cmd.leaves[entity]
        from = cmd.requires[entity]
        [ from, to, cmd ] if to && from != to
      end
    end

    # entity => its transitions. The status graph `rita:verify` walks and a board draws.
    def graph
      entities.to_h { |entity| [ entity, transitions_of(entity) ] }
    end

    # A short name in `invalidates`, resolved namespace-local first, then registry-wide.
    def resolve_invalidation(command, short_name)
      short_name = short_name.to_sym
      candidates = queries.select { |q| q.name_key == short_name }
      candidates.find { |q| q.namespace == command.namespace } || candidates.first
    end

    # The queries a command's `invalidates` lands on; a name that resolves nowhere is
    # dropped here and reported by `rita:verify`.
    def invalidated_by(command)
      command.invalidates.filter_map { |short| resolve_invalidation(command, short) }
    end

    def invalidators_of(query)
      commands.select { |cmd| invalidated_by(cmd).include?(query) }
    end

    # Load every use case under app/use_cases so the registry is complete before routes
    # are drawn or a tool walks it. Idempotent.
    def self.load!
      dir = Rails.root.join("app/use_cases")
      Rails.autoloaders.main.eager_load_dir(dir) if dir.exist?
    end

    private

    def index
      @index ||= @use_cases.to_h { |uc| [ uc.key.to_s, uc ] }
    end
  end
end
