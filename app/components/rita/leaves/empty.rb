# frozen_string_literal: true

module Rita
  module Leaves
    # The empty state: the query's intent as a sentence, and one button per no-keyword
    # command the namespace offers (ADR 009).
    class Empty < Base
      def initialize(intent:, actions:)
        @intent = intent
        @actions = actions
      end

      def view_template
        div(data: { component: "empty" }) do
          p { @intent }
          render Actions.new(name: t("rita.chat.start"), actions: @actions)
        end
      end
    end
  end
end
