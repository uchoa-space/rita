# frozen_string_literal: true

module Rita
  # ADR 007: every domain outcome is a value. Raising is reserved for bugs and infrastructure.
  #
  #   ok(dish: dish)                                  -> ok? == true,  data == { dish: dish }
  #   failure(:too_cheap, floor_cents: 500)           -> failure? == true, code == :too_cheap
  #   failure(:handoff, message: "no reliable context") -> the ladder's last rung
  #
  # Pattern matching: `case result in { ok: true, dish: }` / `in { ok: false, code: :handoff }`.
  # This file is a contract shared by the kernel and the ladder; change it only with an ADR.
  class Result
    attr_reader :code, :message, :data

    def self.ok(**data)
      new(ok: true, data: data)
    end

    def self.failure(code = :failure, message: nil, **data)
      new(ok: false, code: code, message: message, data: data)
    end

    def initialize(ok:, code: nil, message: nil, data: {})
      @ok = ok
      @code = code
      @message = message
      @data = data.freeze
      freeze
    end

    def ok? = @ok
    def failure? = !@ok

    def deconstruct_keys(_keys)
      { ok: @ok, code: @code, message: @message, **@data }
    end

    def to_h = deconstruct_keys(nil)
  end
end
