require "test_helper"

class IngestTest < ActiveSupport::TestCase
  FIXTURE_ROOT = Rails.root.join("test/fixtures/corpus")

  test "ingests project READMEs and ADRs only, chunked and embedded" do
    report = Corpus::Ingest.call(FIXTURE_ROOT)

    assert_equal 2, report.projects
    assert_equal 4, report.documents
    assert_equal 2, report.changed
    assert_equal %w[alpha beta], Project.order(:name).pluck(:name)
    assert_equal %w[alpha/001-salted-water.md alpha/README.md beta/0002-sourdough-starter.md beta/README.md],
                 Document.order(:path).pluck(:path)
    assert_equal %w[adr readme adr readme], Document.order(:path).pluck(:kind)

    adr = Document.find_by!(path: "alpha/001-salted-water.md")
    assert_equal "ADR 001: Cook pasta in salted water", adr.title
    assert_equal 4, adr.chunks.count
    assert_equal 384, adr.chunks.first.embedding.size
    assert_equal 1, Project.find_by!(name: "alpha").knowledge_version
  end

  test "a re-run changes nothing" do
    Corpus::Ingest.call(FIXTURE_ROOT)
    before = [ Document.pluck(:id, :sha), Chunk.pluck(:id), Project.pluck(:knowledge_version) ]

    report = Corpus::Ingest.call(FIXTURE_ROOT)

    assert_equal 0, report.changed
    assert_equal before, [ Document.pluck(:id, :sha), Chunk.pluck(:id), Project.pluck(:knowledge_version) ]
  end

  test "a changed file re-chunks the document and bumps only its project" do
    Dir.mktmpdir do |dir|
      FileUtils.cp_r(FIXTURE_ROOT.children, dir)
      Corpus::Ingest.call(dir)
      File.write(File.join(dir, "beta/README.md"), "# beta\n\nchanged\n\n## New section\n\nmore\n")

      report = Corpus::Ingest.call(dir)

      assert_equal 1, report.changed
      assert_equal 1, Project.find_by!(name: "alpha").knowledge_version
      assert_equal 2, Project.find_by!(name: "beta").knowledge_version
      assert_equal 2, Document.find_by!(path: "beta/README.md").chunks.count
      assert_equal 3, Project.knowledge_version
    end
  end

  test "a removed file drops the document and bumps its project" do
    Dir.mktmpdir do |dir|
      FileUtils.cp_r(FIXTURE_ROOT.children, dir)
      Corpus::Ingest.call(dir)
      File.delete(File.join(dir, "beta/0002-sourdough-starter.md"))

      report = Corpus::Ingest.call(dir)

      assert_equal 1, report.removed
      assert_equal 3, Document.count
      assert_equal 2, Project.find_by!(name: "beta").knowledge_version
    end
  end
end
