# frozen_string_literal: true

module Rita
  module Archetypes
    # The conversation (ADR 003, 009). Reads `thread:` and `messages:`; draws the Thread,
    # then the Empty state or nothing, then the Composer for the command `say:` names,
    # then one Section per remaining key of `returns`. Four states: loading is the frame
    # busy, empty is no messages, failed is the Failure leaf, happy is the log.
    class Chat < Base
      reads :thread, :messages

      # After a command invalidated the thread: append the turns the result carries, or
      # the failure as a system message, into the log — where the reader is.
      def self.changes_after(_query, _command, result)
        turns = if result.ok?
          result.data.values.select { |value| value.is_a?(::Message) }.map { |turn| message_leaf(turn) }
        else
          [ Leaves::Message.new(role: "system", failure: Leaves::Failure.new(code: result.code, message: result.message, data: result.data)) ]
        end
        turns.map { |leaf| ViewResolver::Change.new(:append, Leaves::Thread::LIST_ID, leaf) }
      end

      def self.message_leaf(turn)
        failure = Leaves::Failure.new(code: turn.failure_code, message: turn.failure_message) if turn.failure?
        Leaves::Message.new(role: turn.role, body: turn.body, id: "message-#{turn.id}", failure: failure, sources: turn.sources,
                            rung: turn.rung, cost_usd: turn.cost_usd, latency_ms: turn.latency_ms)
      end

      private

      def draw
        div(data: { archetype: "chat" }) do
          div(data: { region: "conversation" }) do
            render Leaves::Thread.new(messages: messages.map { |turn| self.class.message_leaf(turn) }, busy: @busy)
            render Leaves::Empty.new(intent: use_case.intent, actions: empty_actions) if messages.empty?
            render Leaves::Actions.new(name: t("rita.chat.thread"), actions: actions_on(:thread, thread))
            render Leaves::Composer.new(action: say.path_for(thread: thread), label: t("rita.chat.say")) if thread && say
          end
          sections = @data.except(*self.class.reads)
          div(data: { region: "context" }) { sections.each { |key, value| section(key, value) } } if sections.any?
        end
      end

      def say
        return @say if defined?(@say)

        short = use_case.render_options[:say]
        @say = short && registry.commands_in(use_case.namespace).find { |cmd| cmd.name_key == short.to_sym }
      end

      def empty_actions
        bare_commands.map { |cmd| { label: cmd.intent, path: cmd.path } }
      end

      def section(key, value)
        render Leaves::Section.new(name: key.to_s.humanize, id: key.to_s.dasherize) do
          case value
          when Array then ul { value.each { |item| li { item.respond_to?(:title) ? item.title : item.to_s } } }
          else p { value.to_s }
          end
        end
      end
    end
  end
end
