# frozen_string_literal: true

module Rita
  # `Rita.run` and `Rita.registry`. Extended onto the Rita module by the initializer,
  # which is also what loads this file before the first use case is defined.
  module Kernel
    def registry
      @registry ||= Registry.new
    end

    # check requires -> coerce accepts -> call -> hold to returns -> verify leaves.
    # Tests, seeds and the dispatcher all go through here.
    def run(use_case, **args)
      Run.call(use_case, **args)
    end
  end

  extend Kernel
end
