module Rung
  # Rung 1: a close rewording of an answered question — cosine similarity >= τ over
  # `answers.question_embedding` at this knowledge_version (spaces/004). $0.
  class Semantic
    def initialize(tau:)
      @tau = tau
    end

    def name = "1"

    def call(context, tried)
      hit = Answer.nearest(context.embedding, version: context.knowledge_version) or return nil
      return nil if 1.0 - hit.neighbor_distance < @tau

      Answer.create!(question: context.question, question_embedding: context.embedding,
                     knowledge_version: context.knowledge_version, rung: name, rungs_tried: tried,
                     cited_document_ids: hit.cited_document_ids, body: hit.body, latency_ms: context.latency_ms)
    end
  end
end
