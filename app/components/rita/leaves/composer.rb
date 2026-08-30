# frozen_string_literal: true

module Rita
  module Leaves
    # The labelled textarea and submit of the command `chat` names in `say:`. Targets the
    # thread frame so the frame is busy while the ladder answers; the Stimulus controller
    # clears the field and returns focus after send (ADR 009 obligations).
    class Composer < Base
      FIELD_ID = "composer-text"

      def initialize(action:, label:, frame: Thread::FRAME_ID)
        @action = action
        @label = label
        @frame = frame
      end

      def view_template
        form(method: "post", action: @action, id: "composer",
             data: { component: "composer", turbo_frame: @frame, controller: "composer",
                     action: "turbo:submit-end->composer#reset keydown->composer#keydown" }) do
          authenticity_field
          label(for: FIELD_ID) { @label }
          textarea(id: FIELD_ID, name: "text", rows: 3, required: true, autofocus: true,
                   data: { composer_target: "field" })
          button(type: "submit") { t("rita.chat.send") }
        end
      end
    end
  end
end
