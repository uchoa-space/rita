# frozen_string_literal: true

namespace :rita do
  desc "List every use case, its header, what was derived, and the count of escapes"
  task explain: :environment do
    Rita::Registry.load!
    puts Rita::Explain.report
  end

  desc "Walk the status graph: unproduced, unconsumed, cycles, path collisions, dangling invalidations"
  task verify: :environment do
    Rita::Registry.load!
    defects = Rita::Graph.verify
    Rita::ViewResolver.verify_returns!
    if defects.empty?
      puts "rita:verify: #{Rita.registry.size} use cases, no defects"
    else
      defects.each { |d| puts d }
      abort "rita:verify: #{defects.size} defects"
    end
  end
end
