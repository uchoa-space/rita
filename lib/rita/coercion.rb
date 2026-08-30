# frozen_string_literal: true

module Rita
  # Raw values to the types `accepts` declares. A scalar is converted; a callable is
  # applied; an entity is looked up through its own `rita_coerce(id)` unless the value
  # already is one. Nothing not in `accepts` gets through.
  #
  # A value that cannot be coerced is a domain outcome — bad input — so `coerce` returns
  # a `Result`: ok with the coerced arguments, or `failure(:invalid_argument)`.
  class Coercion
    INTERNAL_KEYS = %i[controller action rita_key authenticity_token format commit utf8].freeze

    def self.coerce(use_case, args)
      new(use_case).coerce(args)
    end

    # Request params to the raw arguments `coerce` takes: `<entity>_id` becomes the
    # entity's key; anything undeclared is dropped.
    def self.arguments_from(use_case, params)
      params = params.to_unsafe_h if params.respond_to?(:to_unsafe_h)
      params = params.to_h.symbolize_keys.except(*INTERNAL_KEYS)
      use_case.accepts.keys.each_with_object({}) do |name, args|
        id_key = :"#{name}_id"
        if params.key?(name) then args[name] = params[name]
        elsif params.key?(id_key) then args[name] = params[id_key]
        end
      end
    end

    def initialize(use_case)
      @use_case = use_case
    end

    def coerce(args)
      coerced = {}
      @use_case.accepts.each do |name, type|
        next unless args.key?(name)

        coerced[name] = convert(name, type, args[name])
      end
      Result.ok(**coerced)
    rescue ArgumentError, TypeError => e
      Result.failure(:invalid_argument, message: e.message, argument: @failed_argument)
    end

    private

    SCALARS = {
      String => ->(v) { String(v) },
      Integer => ->(v) { Integer(v, exception: true) },
      Float => ->(v) { Float(v, exception: true) },
      Symbol => ->(v) { v.to_s.to_sym },
      Hash => ->(v) { v },
      Array => ->(v) { v }
    }.freeze

    def convert(name, type, value)
      @failed_argument = name
      return value if type.is_a?(Module) && value.is_a?(type)

      if SCALARS.key?(type) then SCALARS[type].call(value)
      elsif type.respond_to?(:call) then type.call(value)
      elsif type.respond_to?(:rita_coerce) then type.rita_coerce(value)
      else raise ArgumentError, "#{name}: #{type} cannot coerce #{value.inspect}"
      end
    end
  end
end
