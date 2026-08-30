# frozen_string_literal: true

module Rita
  module Archetypes
    # A command's failure, drawn on its own when no Turbo frame is there to receive it:
    # the layout and the Failure leaf, nothing else.
    class Failed < Base
      def initialize(use_case:, failure:)
        super(use_case: use_case, failure: failure)
      end
    end
  end
end
