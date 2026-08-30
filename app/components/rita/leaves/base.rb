# frozen_string_literal: true

module Rita
  module Leaves
    # Every leaf descends from here. A leaf is the only translation between the closed
    # vocabulary and markup: it emits elements and `data-` attributes, never a `class:`,
    # and takes no `**attributes` — so an obligation written once inside a leaf cannot be
    # undone by a screen (ADR 004).
    class Base < Phlex::HTML
      include Phlex::Rails::Helpers::FormAuthenticityToken
      include Phlex::Rails::Helpers::T

      register_element :turbo_frame

      private

      # The hidden field every POST form carries; forgery protection is on (ADR 010 debt paid).
      def authenticity_field
        input(type: "hidden", name: "authenticity_token", value: form_authenticity_token, autocomplete: "off")
      end
    end
  end
end
