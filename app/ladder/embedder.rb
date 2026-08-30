# Local ONNX embeddings, `all-MiniLM-L6-v2` (384 dims) via `informers` (spaces/004): no key, no
# network, $0, byte-identical across processes. Loaded lazily so a forked test worker loads its
# own runtime (spaces/009).
module Embedder
  MODEL = "Xenova/all-MiniLM-L6-v2"
  DIMENSIONS = 384

  class << self
    def embed(text) = pipeline.call(text)

    def embed_all(texts) = texts.empty? ? [] : pipeline.call(texts)

    def load! = pipeline

    private

    def pipeline
      @pipeline ||= Informers.pipeline("embedding", MODEL)
    end
  end
end
