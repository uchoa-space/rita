# frozen_string_literal: true

module Rita
  # Every registered use case is one route: a query on GET, a command on POST, all to the
  # dispatcher. Literal segments are drawn before dynamic ones so `/notes/write` outranks
  # `/notes/:note_id`; the pairs this ordering decides are what `rita:verify` reports as
  # path collisions.
  class Routes
    def self.draw(router, registry: Rita.registry)
      Registry.load!
      ordered(registry).each do |uc|
        router.match uc.path, to: "rita/dispatch#call", via: uc.verb, defaults: { rita_key: uc.key.to_s }
      end
    end

    def self.ordered(registry)
      registry.each_with_index.sort_by do |uc, i|
        [ uc.path.split("/").map { |seg| seg.start_with?(":") ? 1 : 0 }, i ]
      end.map(&:first)
    end
  end
end
