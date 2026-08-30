# Walks a corpus root (`~/Documents/adr-harvest`): every `<project>/README.md` and
# `<project>/NNN-*.md` / `NNNN-*.md` becomes one Document, chunked by `##` section and embedded
# locally. Idempotent by sha: a re-run with nothing changed writes nothing; any change anywhere
# bumps the corpus-wide `knowledge_version` once (ADR 005, adaptation 1).
module Corpus
  class Ingest
    ADR_FILE = /\A\d{3,4}-.*\.md\z/
    Report = Data.define(:projects, :documents, :chunks, :changed, :removed, :knowledge_version)

    def self.call(root) = new(root).call

    def initialize(root)
      @root = Pathname(root)
    end

    def call
      changed = 0
      seen = []
      project_dirs.each do |dir|
        project = Project.find_or_create_by!(name: dir.basename.to_s)
        corpus_files(dir).each do |file|
          path = file.relative_path_from(@root).to_s
          seen << path
          changed += 1 if ingest_file(project, path, file.read)
        end
      end
      removed = Document.where.not(path: seen).destroy_all.size
      State.bump_knowledge_version! if changed.positive? || removed.positive?
      Report.new(projects: Project.count, documents: Document.count, chunks: Chunk.count,
                 changed: changed, removed: removed, knowledge_version: State.knowledge_version)
    end

    private

    def project_dirs
      @root.children.select { |c| c.directory? && !c.basename.to_s.start_with?(".") }.sort
    end

    def corpus_files(dir)
      dir.children.select { |f| f.file? && corpus_file?(f.basename.to_s) }.sort
    end

    def corpus_file?(name) = name == "README.md" || name.match?(ADR_FILE)

    def kind_of(name) = name == "README.md" ? "readme" : "adr"

    # Returns true when the document was created or changed.
    def ingest_file(project, path, body)
      sha = Document.sha_of(body)
      document = Document.find_or_initialize_by(path: path)
      return false if document.persisted? && document.sha == sha

      Document.transaction do
        document.assign_attributes(project: project, kind: kind_of(File.basename(path)),
                                   title: title_of(body, path), body: body, sha: sha)
        document.save!
        document.chunks.destroy_all
        sections = Chunker.call(body)
        embeddings = Embedder.embed_all(sections)
        sections.each_with_index do |content, i|
          document.chunks.create!(position: i, content: content, embedding: embeddings[i])
        end
      end
      true
    end

    def title_of(body, path)
      body[/^#\s+(.+)$/, 1]&.strip.presence || File.basename(path, ".md")
    end
  end
end
