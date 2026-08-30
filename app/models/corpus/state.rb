# The one row holding the corpus-wide `knowledge_version` (ADR 005, adaptation 1): bumped by
# `corpus:ingest` whenever anything changed, which is what keeps rungs 0 and 1 from serving stale
# knowledge (spaces/014). Questions cross projects, so the version cannot be per project.
module Corpus
  class State < ApplicationRecord
    self.table_name = "corpus_state"

    def self.current = first || create!

    def self.knowledge_version = current.knowledge_version

    def self.bump_knowledge_version! = current.tap { |s| s.increment!(:knowledge_version) }.knowledge_version
  end
end
