# frozen_string_literal: true

# A tiny sample domain, test-only, that exercises the whole kernel: one entity with a
# status, a command that creates it, one that moves it, and the queries that read it.
module Journal
  class Note
    attr_reader :id, :text
    attr_accessor :status

    def self.store = (@store ||= {})
    def self.reset! = store.clear

    def self.write(text)
      note = new(store.size + 1, text)
      store[note.id] = note
    end

    def self.rita_coerce(id) = store.fetch(Integer(id)) { raise ArgumentError, "no note #{id.inspect}" }

    def initialize(id, text)
      @id = id
      @text = text
      @status = :written
    end

    def written? = status == :written
    def archived? = status == :archived
    def to_h = { id: id, text: text, status: status }
    def as_json(*) = to_h
  end

  class Write < Rita::Command
    intent      "Write a note"
    accepts     text: String
    leaves      note: :written
    returns     note: Note
    invalidates :recent

    def call(text:)
      return failure(:blank, message: "a note needs text") if text.strip.empty?

      ok(note: Note.write(text))
    end
  end

  class Archive < Rita::Command
    intent      "Put a note away"
    accepts     note: Note
    requires    note: :written
    leaves      note: :archived
    returns     note: Note
    invalidates :recent, :note_detail

    def call(note:)
      note.status = :archived
      ok(note: note)
    end
  end

  class Recent < Rita::Query
    intent  "The last notes written"
    accepts limit: Integer
    returns notes: Array
    renders :list

    def call(limit: 10) = ok(notes: Note.store.values.select(&:written?).last(limit))
  end

  class NoteDetail < Rita::Query
    intent  "One note"
    accepts note: Note
    returns note: Note
    renders :detail

    def call(note:) = ok(note: note)
  end

  class Archived < Rita::Query
    intent   "An archived note, read-only"
    accepts  note: Note
    requires note: :archived
    returns  note: Note
    renders  :custom, because: "an archived note is shown struck through, which no archetype draws"

    def call(note:) = ok(note: note)
  end
end
