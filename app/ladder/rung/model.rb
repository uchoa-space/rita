module Rung
  # Rungs 2 and 3: retrieved chunks, one model call, accepted only if the answer is non-empty and
  # every cited id is in the retrieved set (spaces/015). A missing key, a failed request,
  # malformed JSON or an empty citation misses the rung with a warning (spaces/008).
  class Model
    attr_reader :name

    def initialize(name:, client:)
      @name = name
      @client = client
    end

    def call(context, tried)
      return skip("nothing retrieved") if context.retrieved.empty?

      completion = @client.complete(system: Llm::Prompt.system, user: Llm::Prompt.user(context.question, context.retrieved))
      return skip(completion.message) if completion.failure?

      parsed = parse(completion.data[:text]) or return skip("malformed JSON")
      body, cited = parsed
      return skip("empty answer or citation") if body.blank? || cited.empty?
      return skip("cited #{cited - context.retrieved_ids} outside the retrieved set") unless (cited - context.retrieved_ids).empty?

      record(context, tried, completion.data, body, cited)
    end

    private

    def parse(text)
      parsed = JSON.parse(text)
      return nil unless parsed.is_a?(Hash) && parsed["cited"].is_a?(Array)

      [ parsed["answer"].to_s.strip, parsed["cited"].map { |id| Integer(id) } ]
    rescue JSON::ParserError, ArgumentError, TypeError
      nil
    end

    def record(context, tried, data, body, cited)
      documents = context.retrieved.select { |chunk| cited.include?(chunk.id) }.map(&:document_id).uniq
      Answer.create!(question: context.question, question_embedding: context.embedding,
                     knowledge_version: context.knowledge_version, rung: name, rungs_tried: tried,
                     model: @client.model, body: body, cited_document_ids: documents,
                     input_tokens: data[:input_tokens], output_tokens: data[:output_tokens],
                     cost_usd: Llm.cost_usd(@client.model, input_tokens: data[:input_tokens], output_tokens: data[:output_tokens]),
                     latency_ms: context.latency_ms)
    end

    def skip(reason)
      Rails.logger.warn("[ladder] rung #{name} (#{@client.model}) skipped: #{reason}")
      nil
    end
  end
end
