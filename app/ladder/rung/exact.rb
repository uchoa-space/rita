module Rung
  # Rung 0: the same question, already answered at this knowledge_version. $0.
  class Exact
    def name = "0"

    def call(context, tried)
      hit = Answer.exact(context.question, version: context.knowledge_version) or return nil
      Answer.create!(question: context.question, question_embedding: context.embedding,
                     knowledge_version: context.knowledge_version, rung: name, rungs_tried: tried,
                     cited_document_ids: hit.cited_document_ids, body: hit.body, latency_ms: context.latency_ms)
    end
  end
end
