# frozen_string_literal: true

# Loads the kernel seam (`Rita.run`, `Rita.registry`) before any use case is defined,
# and again on every reload so a redefined use case re-registers under its name.
Rails.application.config.to_prepare do
  Rita::Kernel
end
