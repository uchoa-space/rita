# Nothing answers a question except `Ladder.ask` (spaces/014). Every question climbs the rungs in
# order — exact cache, semantic cache, small model, large model — and stops at the first that
# writes an Answer; when none does, the handoff writes its own row and is returned as
# `Rita::Result.failure(:handoff)` (ADR 005, ADR 007). Rungs never raise for a domain outcome:
# a missing key, a failed request or an invented citation misses the rung (spaces/008, 015).
module Ladder
  HANDOFF_MESSAGE = "no reliable context"

  Context = Data.define(:question, :embedding, :knowledge_version, :retrieved, :started_at) do
    def latency_ms = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond) - started_at
    def retrieved_ids = retrieved.map(&:id)
  end

  def self.config = Rails.application.config.x.ladder

  def self.ask(question, clients: Llm.default_clients)
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
    embedding = Embedder.embed(question)
    context = Context.new(question: question, embedding: embedding, knowledge_version: Corpus.knowledge_version,
                          retrieved: Chunk.retrieve(embedding, limit: config.top_k).to_a, started_at: started_at)
    tried = []
    rungs(clients).each do |rung|
      tried << rung.name
      answer = rung.call(context, tried)
      return landed(answer) if answer
    end
    handoff(context, tried)
  end

  def self.rungs(clients)
    [ Rung::Exact.new, Rung::Semantic.new(tau: config.semantic_tau),
      Rung::Model.new(name: "2", client: clients.fetch(:small)),
      Rung::Model.new(name: "3", client: clients.fetch(:large)) ]
  end

  def self.landed(answer)
    Rita::Result.ok(answer: answer, rung: answer.rung, body: answer.body,
                    cited_document_ids: answer.cited_document_ids, cost_usd: answer.cost_usd,
                    latency_ms: answer.latency_ms)
  end

  def self.handoff(context, tried)
    answer = Answer.create!(question: context.question, question_embedding: context.embedding,
                            knowledge_version: context.knowledge_version, rung: "handoff",
                            rungs_tried: tried, latency_ms: context.latency_ms)
    Rita::Result.failure(:handoff, message: HANDOFF_MESSAGE, answer: answer, retrieved: context.retrieved_ids,
                         rungs_tried: tried)
  end
  private_class_method :rungs, :landed, :handoff
end
