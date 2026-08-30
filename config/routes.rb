Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Every registered use case: queries on GET, commands on POST, all to Rita::DispatchController.
  Rita::Routes.draw(self)
end
