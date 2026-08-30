class CreateCorpus < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :projects, :name, unique: true

    # One row: the corpus-wide knowledge_version rungs 0-1 key on (ADR 005, adaptation 1).
    create_table :corpus_state do |t|
      t.integer :knowledge_version, null: false, default: 0
      t.timestamps
    end

    create_table :documents do |t|
      t.references :project, null: false, foreign_key: true
      t.string :path, null: false
      t.string :kind, null: false
      t.string :title, null: false
      t.text :body, null: false
      t.string :sha, null: false
      t.timestamps
    end
    add_index :documents, :path, unique: true
    add_check_constraint :documents, "kind IN ('adr', 'readme', 'note')", name: "documents_kind_check"

    create_table :chunks do |t|
      t.references :document, null: false, foreign_key: true
      t.integer :position, null: false
      t.text :content, null: false
      t.vector :embedding, limit: 384, null: false
      t.timestamps
    end
    add_index :chunks, [ :document_id, :position ], unique: true
  end
end
