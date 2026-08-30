# frozen_string_literal: true

module Rita
  # The one path through which a use case ever runs. Every step before and after the
  # body is a check the header promised; the body is the only thing that writes.
  class Run
    def self.call(use_case, **args)
      new(use_case, **args).call
    end

    # Does the entity answer the status a `requires` or `leaves` clause names.
    def self.status_satisfied?(entity, status)
      predicate = :"#{status}?"
      if entity.respond_to?(predicate) then entity.public_send(predicate)
      elsif entity.respond_to?(:status) then entity.status.to_s == status.to_s
      else false
      end
    end

    def initialize(use_case, **args)
      @use_case = use_case.is_a?(Class) ? use_case : Rita.registry[use_case]
      raise ArgumentError, "Unknown use case #{use_case.inspect}" unless @use_case

      @args = args
    end

    def call
      coerced = Coercion.coerce(@use_case, @args)
      return coerced if coerced.failure?

      args = coerced.data
      unmet = unmet_precondition(args)
      return guard_failure(*unmet) if unmet

      missing = @use_case.required_keywords - args.keys
      return Result.failure(:missing_argument, message: "missing #{missing.join(', ')}", missing: missing) if missing.any?

      result = @use_case.new.call(**args)
      raise DefinitionError, "#{@use_case.key} returned #{result.class}, not a Rita::Result" unless result.is_a?(Result)
      return result if result.failure?

      hold_to_returns(result)
      verify_leaves(result, args)
      result
    end

    private

    def unmet_precondition(args)
      @use_case.requires.find { |entity, status| !self.class.status_satisfied?(args[entity], status) }
    end

    def guard_failure(entity, status)
      Result.failure(:guard_failed, message: "#{entity} is not #{status}", entity: entity, status: status)
    end

    def hold_to_returns(result)
      declared = @use_case.returns
      return if declared.empty?

      undeclared = result.data.keys - declared.keys
      omitted = declared.keys - result.data.keys
      return if undeclared.empty? && omitted.empty?

      raise DefinitionError,
            "#{@use_case.key} returns #{declared.keys.inspect}; got undeclared #{undeclared.inspect}, omitted #{omitted.inspect}"
    end

    # Verified, never performed (cuy/0006). Raise where a lying header cannot hurt
    # anyone; log where it can.
    def verify_leaves(result, args)
      @use_case.leaves.each do |entity_name, status|
        entity = result.data.key?(entity_name) ? result.data[entity_name] : args[entity_name]
        next if self.class.status_satisfied?(entity, status)

        message = "#{@use_case.key} leaves #{entity_name}: :#{status}, but it is not after call"
        raise PostconditionError, message if Rails.env.local?

        Rails.logger.error("rita.postcondition_failed #{message}")
      end
    end
  end
end
