class CreateAnswers < ActiveRecord::Migration[8.1]
  def change
    create_table :answers do |t|
      t.text :question, null: false
      t.vector :question_embedding, limit: 384, null: false
      t.integer :knowledge_version, null: false
      t.string :rung, null: false
      t.integer :cited_document_ids, array: true, null: false, default: []
      t.decimal :cost_usd, precision: 12, scale: 8, null: false, default: 0
      t.integer :latency_ms, null: false, default: 0
      t.integer :input_tokens, null: false, default: 0
      t.integer :output_tokens, null: false, default: 0
      t.string :model
      t.text :body, null: false
      t.timestamps
    end
    add_index :answers, [ :knowledge_version, :question ]
    add_check_constraint :answers, "rung IN ('0', '1', '2', '3', 'handoff')", name: "answers_rung_check"
  end
end
