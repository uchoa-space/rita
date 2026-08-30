# frozen_string_literal: true

module Rita
  # The declarative header every use case carries (ADR 002). The header is the spec: the
  # kernel derives the route, the guard, the form, the screen and the invalidations from
  # it; the body (`call`) is the only hand-written logic.
  #
  #   module Notes
  #     class Write < Rita::Command
  #       intent      "Write a note"
  #       accepts     text: String
  #       leaves      note: :written
  #       returns     note: Note
  #       invalidates :recent
  #
  #       def call(text:) = ok(note: Note.write(text))
  #     end
  #   end
  #
  # Bodies return a `Rita::Result` — `ok(**data)` or `failure(code, message:, **data)`.
  # A `rescue` inside a body is forbidden by convention: every domain outcome is a value,
  # and an exception is a bug or dead infrastructure that must surface as such (ADR 007).
  class UseCase
    # Types that are parameters, not entities: they never nest a path segment.
    SCALAR_TYPES = [ String, Integer, Float, Symbol, Hash, Array ].freeze

    class << self
      def inherited(subclass)
        super
        Rita.registry.register(subclass) if subclass.name.present? && !subclass.name.start_with?("Rita::")
      end

      def kind = :use_case
      def command? = kind == :command
      def query? = kind == :query
      def verb = command? ? :post : :get

      def intent(sentence = nil)
        return @intent if sentence.nil?

        @intent = sentence.to_s.freeze
      end

      # name => type. A scalar type (SCALAR_TYPES) is a parameter; a callable is a custom
      # coercion; anything else is an entity, coerced from `<name>_id` by its own
      # `rita_coerce(id)`.
      def accepts(**types)
        return (@accepts ||= {}.freeze) if types.empty?

        @accepts = types.freeze
      end

      def entities
        accepts.reject { |_, type| scalar?(type) || type.respond_to?(:call) }
      end

      def parameters
        accepts.reject { |name, _| entities.key?(name) }
      end

      # entity => status. A precondition: `Rita.run` refuses the call with
      # `failure(:guard_failed)` unless the entity answers `<status>?` (or its `status`).
      def requires(**conditions)
        return (@requires ||= {}.freeze) if conditions.empty?

        conditions.each_key do |entity|
          next if accepts.key?(entity)

          raise DefinitionError, "#{name} requires :#{entity}, which is not in accepts #{accepts.keys.inspect}"
        end
        @requires = conditions.transform_values(&:to_sym).freeze
      end

      # entity => status. A postcondition, verified after `call` and never performed by
      # the kernel. The entity is read from the result, then from the arguments — so a
      # command may leave an entity it creates rather than accepts.
      def leaves(**conditions)
        return (@leaves ||= {}.freeze) if conditions.empty?

        @leaves = conditions.transform_values(&:to_sym).freeze
      end

      # key => type. Held in both directions on the ok branch: an undeclared or an
      # omitted key is a DefinitionError. Undeclared means unconstrained.
      def returns(**shape)
        return (@returns ||= {}.freeze) if shape.empty?

        @returns = shape.freeze
      end

      # Short names of the queries that go stale when this command succeeds. Resolved by
      # the registry: namespace-local first, then registry-wide.
      def invalidates(*names)
        return (@invalidates ||= [].freeze) if names.empty?

        @invalidates = names.flatten.map(&:to_sym).freeze
      end

      # The archetype that draws this use case, with its options. `renders :custom,
      # because: "..."` is the counted escape; `:custom` without a reason is a
      # DefinitionError.
      def renders(archetype = nil, **options)
        return @archetype if archetype.nil?

        archetype = archetype.to_sym
        if archetype == :custom && options[:because].blank?
          raise DefinitionError, "#{name} renders :custom without a because:"
        end

        @archetype = archetype
        @render_options = options.freeze
      end

      def render_options = @render_options || {}
      def archetype = @archetype || (command? ? :form : nil)
      def custom? = archetype == :custom
      def escape_reason = render_options[:because]

      # Derived from the header; `path "/..."` overrides.
      def path(custom = nil)
        return @path = custom.to_s.freeze if custom

        @path || derive_path
      end

      # The path with every `:<entity>_id` filled from the entities given; a segment with
      # nothing to fill stays as it is.
      def path_for(**entities)
        path.gsub(/:(\w+)_id/) do
          entity = entities[Regexp.last_match(1).to_sym]
          entity.respond_to?(:id) ? entity.id.to_s : Regexp.last_match(0)
        end
      end

      def key = name ? name.underscore.to_sym : :anonymous
      def namespace = name&.include?("::") ? name.deconstantize.underscore.to_sym : nil
      def name_key = name ? name.demodulize.underscore.to_sym : :anonymous

      # Keywords the body's `call` takes, and which of them it cannot do without.
      def call_keywords
        instance_method(:call).parameters.filter_map { |type, kw| kw if %i[key keyreq].include?(type) }
      end

      def required_keywords
        instance_method(:call).parameters.filter_map { |type, kw| kw if type == :keyreq }
      end

      private

      def scalar?(type) = SCALAR_TYPES.include?(type)

      # no entities                       -> /ns/name_key
      # one entity created (left, not required) -> /ns/entities/name_key
      # entities acted on                 -> /ns/entities/:entity_id/name_key
      # the member query `<entity>_detail` rendering :detail -> /ns/entities/:entity_id
      def derive_path
        segments = [ namespace, *entity_segments ]
        segments << name_key unless member_query?
        "/#{segments.compact.join('/')}"
      end

      def entity_segments
        entities.keys.flat_map do |entity|
          created = leaves.key?(entity) && !requires.key?(entity)
          created && entities.size == 1 ? [ entity.to_s.pluralize ] : [ entity.to_s.pluralize, ":#{entity}_id" ]
        end
      end

      def member_query?
        archetype == :detail && entities.size == 1 && name_key == :"#{entities.keys.first}_detail"
      end
    end

    def ok(**data) = Result.ok(**data)

    def failure(code = :failure, message: nil, **data) = Result.failure(code, message: message, **data)
  end
end
