# frozen_string_literal: true

module Rita
  module Leaves
    # A named group of commands, one POST button each. An unavailable action is absent —
    # the caller derives the list from `requires`, and an empty list renders nothing —
    # never disabled (ADR 009).
    class Actions < Base
      def initialize(name:, actions:)
        @name = name
        @actions = actions
      end

      def view_template
        return if @actions.empty?

        nav(data: { component: "actions" }, aria: { label: @name }) do
          @actions.each do |action|
            form(method: "post", action: action.fetch(:path)) do
              authenticity_field
              button(type: "submit") { action.fetch(:label) }
            end
          end
        end
      end
    end
  end
end
