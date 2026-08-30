require "test_helper"

class DocumentTest < ActiveSupport::TestCase
  test "kind is adr, readme or note" do
    project = Project.create!(name: "p")
    doc = Document.new(project: project, path: "p/x.md", title: "x", body: "b", sha: Document.sha_of("b"))
    %w[adr readme note].each { |k| doc.kind = k; assert doc.valid?, k }
    doc.kind = "post"
    assert_not doc.valid?
  end

  test "corpus knowledge_version is one row, starts at 0 and bumps" do
    assert_equal 0, Corpus.knowledge_version
    assert_equal 1, Corpus::State.bump_knowledge_version!
    assert_equal 1, Corpus.knowledge_version
    assert_equal 1, Corpus::State.count
  end
end
