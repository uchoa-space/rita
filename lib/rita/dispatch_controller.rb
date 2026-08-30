# frozen_string_literal: true

module Rita
  # The only controller. Resolves the use case from the route, coerces the request into
  # its `accepts`, runs it, and — for now — answers JSON: the result on ok, 422 on
  # failure. Screen rendering will hang off ViewResolver.
  class DispatchController < ::ApplicationController
    skip_forgery_protection

    def call
      use_case = Rita.registry[params[:rita_key]]
      return head :not_found unless use_case

      result = Rita.run(use_case, **Coercion.arguments_from(use_case, params))
      render json: result.to_h, status: (result.ok? ? :ok : :unprocessable_entity)
    end
  end
end
