require "test_helper"

class ChunkerTest < ActiveSupport::TestCase
  test "splits by ## with the preamble first and drops blanks" do
    body = "# Title\n\nintro\n\n## A\n\na text\n\n## B\n\n\n## C\n\nc text\n"
    assert_equal [ "# Title\n\nintro", "## A\n\na text", "## B", "## C\n\nc text" ], Corpus::Chunker.call(body)
  end

  test "a body without headings is one chunk" do
    assert_equal [ "just text" ], Corpus::Chunker.call("just text\n")
  end
end
