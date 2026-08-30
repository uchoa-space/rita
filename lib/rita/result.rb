# frozen_string_literal: true

module Rita
  # ADR 007: every domain outcome is a value; raising is reserved for bugs and dead
  # infrastructure. Pattern match on `{ ok: true, data: }` / `{ failure: true, code: }`.
  class Result
    attr_reader :code, :message, :data

    def self.ok(**data)
      new(ok: true, data: data)
    end

    def self.failure(code, message: nil, **data)
      new(ok: false, code: code.to_sym, message: message, data: data)
    end

    def initialize(ok:, data:, code: nil, message: nil)
      @ok = ok
      @code = code
      @message = message
      @data = data.freeze
      freeze
    end

    def ok? = @ok

    def failure? = !@ok

    def deconstruct_keys(_keys)
      { ok: @ok, failure: !@ok, code: @code, message: @message, data: @data }
    end

    private_class_method :new
  end
end
