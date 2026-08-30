namespace :corpus do
  desc "Ingest the ADR corpus (CORPUS_ROOT, default ~/Documents/adr-harvest) — idempotent by sha"
  task ingest: :environment do
    root = ENV.fetch("CORPUS_ROOT", File.expand_path("~/Documents/adr-harvest"))
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    report = Corpus::Ingest.call(root)
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
    puts "corpus: #{report.projects} projects, #{report.documents} documents, #{report.chunks} chunks"
    puts "corpus: #{report.changed} documents changed, #{report.removed} removed, " \
         "knowledge_version #{report.knowledge_version}, #{elapsed.round(1)}s"
  end
end
