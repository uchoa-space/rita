# frozen_string_literal: true

# Loads the kernel seam (`Rita.run`, `Rita.registry`) before any use case is defined, and
# names the archetypes that draw screens — again on every reload, so a redefined use case
# or archetype re-registers under its name.
Rails.application.config.to_prepare do
  Rita::Seam
  Rita::ViewResolver.archetypes = { chat: Rita::Archetypes::Chat }
end

# Boot-time audits (ADR 004, 008): the theme's contrast and class-free selectors, and
# every query's `returns` against what its archetype reads. A defect fails boot in
# development and test.
Rails.application.config.after_initialize do
  Rita::Theme.verify!
  Rita::Registry.load!
  Rita::ViewResolver.verify_returns!
end
