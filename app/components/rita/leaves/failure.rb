# frozen_string_literal: true

module Rita
  module Leaves
    # A `Rita::Result` failure rendered where the reader is, never as a toast (ADR 007).
    # The sentence is `errors.domain.<code>` with the result's scalar data interpolated;
    # the result's own message is the fallback.
    class Failure < Base
      def initialize(code:, message: nil, data: {})
        @code = code.to_s
        @message = message
        @data = data
      end

      def view_template
        div(data: { component: "failure", code: @code }, role: "status") do
          strong { t("rita.failure") }
          plain " "
          span { sentence }
        end
      end

      private

      def sentence
        interpolations = @data.select { |_, v| v.is_a?(String) || v.is_a?(Numeric) || v.is_a?(Symbol) }
        I18n.t("errors.domain.#{@code}", **interpolations, default: @message.presence || @code.humanize)
      end
    end
  end
end
