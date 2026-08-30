# frozen_string_literal: true

module Chat
  # The conversation screen, and the root of the app: with no thread given it shows the
  # latest open one — or the empty state, whose only action is to open one.
  class Thread < Rita::Query
    intent  "Talk a post through with the corpus"
    accepts thread: ChatThread
    returns thread: ChatThread, messages: Array
    renders :chat, say: :say
    path    "/chat/threads/:thread_id"

    def call(thread: ChatThread.current)
      ok(thread: thread, messages: thread ? thread.messages.includes(answer: { cited_documents: :project }).to_a : [])
    end
  end
end
