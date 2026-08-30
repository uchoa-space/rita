# frozen_string_literal: true

module Rita
  module Leaves
    # One turn, named by its role in words — never told apart by colour alone. Parts:
    # `text` (paragraphs), `failure` (a Failure leaf where the reader is, ADR 007),
    # `sources` (the cited documents), `meta` (rung, USD, latency — every answer carries them).
    class Message < Base
      ROLES = %w[user assistant system].freeze

      def initialize(role:, body: nil, id: nil, failure: nil, sources: [], rung: nil, cost_usd: nil, latency_ms: nil)
        raise ArgumentError, "role must be one of #{ROLES.inspect}" unless ROLES.include?(role.to_s)

        @role = role.to_s
        @body = body
        @id = id
        @failure = failure
        @sources = sources
        @rung = rung
        @cost_usd = cost_usd
        @latency_ms = latency_ms
      end

      def view_template
        li(id: @id, data: { component: "message", role: @role }, aria: { label: author }) do
          header(data: { part: "author" }) { author }
          text_part
          render @failure if @failure
          render Sources.new(documents: @sources) if @sources.any?
          meta_part
        end
      end

      private

      def author = t("rita.chat.roles.#{@role}")

      def text_part
        return if @body.blank?

        div(data: { part: "text" }) do
          @body.to_s.split(/\n{2,}/).each { |paragraph| p { paragraph.strip } }
        end
      end

      def meta_part
        return if @rung.nil?

        p(data: { part: "meta" }) do
          span { t("rita.chat.meta.rung", rung: @rung) }
          plain " · "
          span { t("rita.chat.meta.cost", usd: Kernel.format("%.4f", @cost_usd.to_f)) }
          plain " · "
          span { t("rita.chat.meta.latency", ms: @latency_ms.to_i) }
        end
      end
    end
  end
end
