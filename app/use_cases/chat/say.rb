# frozen_string_literal: true

module Chat
  # One turn: the user's text is written, the ladder is asked, and the assistant's turn is
  # written from whatever came back — a landed answer, or the handoff as a failure the
  # message carries (ADR 005 adaptation 2, ADR 007). Nothing here raises for an outcome.
  class Say < Rita::Command
    intent      "Say something"
    accepts     thread: ChatThread, text: String
    requires    thread: :open
    leaves      thread: :open
    returns     thread: ChatThread, message: Message, reply: Message
    invalidates :thread

    def call(thread:, text:)
      return failure(:blank, message: "say something first") if text.strip.empty?

      message = thread.messages.create!(role: "user", body: text.strip)
      reply = thread.messages.create!(role: "assistant", **reply_attributes(Ladder.ask(text.strip)))
      ok(thread: thread, message: message, reply: reply)
    end

    private

    def reply_attributes(result)
      case result
      in { ok: true, answer:, body: } then { body: body, answer: answer }
      in { ok: false, code:, message:, answer: } then { answer: answer, failure_code: code.to_s, failure_message: message }
      in { ok: false, code:, message: } then { failure_code: code.to_s, failure_message: message }
      end
    end
  end
end
