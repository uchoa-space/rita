# frozen_string_literal: true

module Chat
  # Start a conversation. The one no-keyword command of the namespace, so the empty
  # state's one button; leaves the thread open, which `Say` requires.
  class Open < Rita::Command
    intent      "Open a thread"
    leaves      thread: :open
    returns     thread: ChatThread
    invalidates :thread

    def call = ok(thread: ChatThread.create!)
  end
end
