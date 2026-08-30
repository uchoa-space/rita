require "test_helper"

class DocumentTest < ActiveSupport::TestCase
  test "kind is adr, readme or note" do
    project = Project.create!(name: "p")
    doc = Document.new(project: project, path: "p/x.md", title: "x", body: "b", sha: Document.sha_of("b"))
    %w[adr readme note].each { |k| doc.kind = k; assert doc.valid?, k }
    doc.kind = "post"
    assert_not doc.valid?
  end

  test "project knowledge_version sums the projects" do
    Project.create!(name: "a", knowledge_version: 2)
    Project.create!(name: "b", knowledge_version: 3)
    assert_equal 5, Project.knowledge_version
  end
end
