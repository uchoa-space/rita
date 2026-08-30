# frozen_string_literal: true

module Rita
  # The only controller. Resolves the use case from the route, coerces the request into
  # its `accepts`, runs it, and answers: a query draws its archetype's screen (200, or
  # 422 with the failure where the reader is); a command answers Turbo Streams with the
  # frames its result changes, or redirects to the screen it invalidated. A query whose
  # archetype is not drawn yet (ADR 003) answers JSON, provisionally.
  class DispatchController < ::ApplicationController
    def call
      use_case = Rita.registry[params[:rita_key]]
      return head :not_found unless use_case

      result = Rita.run(use_case, **Coercion.arguments_from(use_case, params))
      use_case.query? ? draw(use_case, result) : answer(use_case, result)
    end

    private

    def status_of(result) = result.ok? ? :ok : :unprocessable_entity

    def draw(use_case, result)
      screen = ViewResolver.resolve(use_case, result)
      return render json: result.to_h, status: status_of(result) unless screen

      render screen, layout: false, status: status_of(result)
    end

    def answer(use_case, result)
      if request.format.turbo_stream?
        render turbo_stream: turbo_streams_for(use_case, result), status: status_of(result)
      elsif result.ok?
        redirect_to ViewResolver.landing_path(use_case, result), status: :see_other
      elsif ViewResolver.archetypes.empty?
        render json: result.to_h, status: :unprocessable_entity
      else
        render Rita::Archetypes::Failed.new(use_case: use_case, failure: result), layout: false, status: :unprocessable_entity
      end
    end

    def turbo_streams_for(use_case, result)
      changes = ViewResolver.changes_after(use_case, result)
      changes = [ ViewResolver::Change.new(:append, Leaves::Thread::LIST_ID, failure_message(result)) ] if changes.empty? && result.failure?
      changes.map { |change| turbo_stream.public_send(change.action, change.target, change.component.render_in(view_context)) }.join
    end

    def failure_message(result)
      Leaves::Message.new(role: "system", failure: Leaves::Failure.new(code: result.code, message: result.message, data: result.data))
    end
  end
end
