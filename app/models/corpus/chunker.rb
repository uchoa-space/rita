# Splits a Markdown body by `##` heading; the preamble (title and anything before the first
# `##`) is the first chunk. Blank sections are dropped.
module Corpus
  module Chunker
    HEADING = /^(?=## )/

    def self.call(body)
      body.split(HEADING).map(&:strip).reject(&:empty?)
    end
  end
end
