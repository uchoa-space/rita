# frozen_string_literal: true

module Rita
  module Leaves
    # A named region of a screen: an `h2` — the only heading below the layout's `h1` —
    # and whatever the archetype draws from one key of `returns`.
    class Section < Base
      def initialize(name:, id:)
        @name = name
        @id = id
      end

      def view_template(&block)
        section(data: { component: "section" }, aria: { labelledby: "#{@id}-heading" }) do
          h2(id: "#{@id}-heading") { @name }
          render(block)
        end
      end
    end
  end
end
