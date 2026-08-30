# frozen_string_literal: true

module Rita
  module Archetypes
    # What every archetype shares: the keys it `reads` off the query's `returns`, the
    # result it draws (data on ok, the failure otherwise), and the layout around it.
    # Nothing here names a domain; the registry answers every question.
    class Base < Leaves::Base
      class << self
        def reads(*keys)
          return (@reads ||= [].freeze) if keys.empty?

          @reads = keys.map(&:to_sym).freeze
          @reads.each { |key| define_method(key) { @data[key] } }
          private(*@reads)
        end

        # The frames this archetype changes after `command` ran for `query`; none by default.
        def changes_after(_query, _command, _result) = []
      end

      def initialize(use_case:, data: {}, failure: nil, busy: false)
        @use_case = use_case
        @data = data
        @failure = failure
        @busy = busy
      end

      def view_template
        render Leaves::Layout.new(title: t("rita.title")) do
          if @failure
            render Leaves::Failure.new(code: @failure.code, message: @failure.message, data: @failure.data)
          else
            draw
          end
        end
      end

      private

      attr_reader :use_case

      def registry = Rita.registry

      # The commands of this namespace that take nothing: the empty state's buttons.
      def bare_commands
        registry.commands_in(use_case.namespace).select { |cmd| cmd.accepts.empty? }
      end

      # The commands of this namespace acting on `entity` alone whose `requires` the
      # entity satisfies; an unsatisfiable one is absent, never disabled.
      def actions_on(name, entity)
        return [] if entity.nil?

        registry.commands_in(use_case.namespace).select do |cmd|
          cmd.accepts.keys == [ name ] && cmd.requires.all? { |e, status| Rita::Run.status_satisfied?(entity, status) && e == name }
        end.map { |cmd| { label: cmd.intent, path: cmd.path_for(name => entity) } }
      end
    end
  end
end
