# frozen_string_literal: true

module Rita
  # ADR 007: every domain outcome is a value; raising is reserved for bugs and dead
  # infrastructure. Pattern match on `{ ok: true, data: }` / `{ failure: true, code: }`.
  # ADR 010, diverged on purpose: `data` is nested and `failure:` explicit, unlike the removed
  # splatting shape, so a data key can never shadow `code`/`message`.
  class Result
    attr_reader :code, :message, :data

    def self.ok(**data)
      new(ok: true, data: data)
    end

    def self.failure(code, message: nil, **data)
      unless code.respond_to?(:to_sym)
        raise DefinitionError, "failure code must be a Symbol or String, got #{code.inspect}"
      end

      new(ok: false, code: code.to_sym, message: message, data: data)
    end

    def initialize(ok:, data:, code: nil, message: nil)
      @ok = ok
      @code = code
      @message = message
      @data = deep_freeze(data)
      freeze
    end

    def ok? = @ok

    def failure? = !@ok

    def deconstruct_keys(_keys)
      { ok: @ok, failure: !@ok, code: @code, message: @message, data: @data }
    end

    private_class_method :new

    private

    # ADR 007: a value nobody can mutate downstream — a leaf sorting `rows` in place would make
    # the stream and the screen disagree. Only what Ruby itself builds is walked.
    def deep_freeze(value)
      case value
      when Hash then value.each_value { |v| deep_freeze(v) }
      when Array then value.each { |v| deep_freeze(v) }
      end
      value.freeze if value.is_a?(Hash) || value.is_a?(Array) || value.is_a?(String)
      value
    end
  end
end
