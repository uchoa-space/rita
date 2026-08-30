# frozen_string_literal: true

module Rita
  module Leaves
    # The documents an answer cited, as a named group of titles. Links come when the
    # corpus screens exist (ADR 003, order 3); until then a title has nowhere to lead.
    class Sources < Base
      def initialize(documents:)
        @documents = documents
      end

      def view_template
        return if @documents.empty?

        div(data: { part: "sources", component: "sources" }, role: "group", aria: { label: t("rita.chat.sources") }) do
          p { t("rita.chat.sources") }
          ul do
            @documents.each do |document|
              li(data: { document_id: document.id }) do
                cite { document.title }
                plain " — "
                span { document.path }
              end
            end
          end
        end
      end
    end
  end
end
