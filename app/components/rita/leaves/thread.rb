# frozen_string_literal: true

module Rita
  module Leaves
    # The conversation log. `role="log"` and `aria-live="polite"` live here and nowhere
    # else; the frame is what a `Say` targets, so `turbo-frame[busy]` is the typing state
    # (ADR 009) — `busy:` renders it server-side for the loading state.
    class Thread < Base
      FRAME_ID = "thread"
      LIST_ID = "messages"

      def initialize(messages:, busy: false)
        @messages = messages
        @busy = busy
      end

      def view_template
        turbo_frame(id: FRAME_ID, busy: @busy, aria: { busy: @busy ? "true" : nil }) do
          div(data: { component: "thread" }, role: "log", aria: { live: "polite", label: t("rita.chat.thread") }) do
            ol(id: LIST_ID) { @messages.each { |message| render message } }
          end
          p(data: { component: "typing" }, role: "status") { t("rita.chat.typing") }
        end
      end
    end
  end
end
