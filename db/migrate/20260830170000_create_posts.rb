class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.references :thread, null: false, foreign_key: { to_table: :chat_threads }
      t.string :slug, null: false
      t.text :angle
      t.text :tension
      t.text :payoff_or_cost
      t.string :status, null: false, default: "seed"
      t.text :draft
      t.string :published_path
      t.integer :retrieved_chunk_ids, array: true, null: false, default: []
      t.timestamps
    end
    add_index :posts, :slug, unique: true
    add_check_constraint :posts, "status IN ('seed', 'drafting', 'approved', 'published')", name: "posts_status_check"

    create_table :post_sources do |t|
      t.references :post, null: false, foreign_key: true
      t.references :document, null: false, foreign_key: true
      t.timestamps
    end
    add_index :post_sources, [ :post_id, :document_id ], unique: true

    add_reference :messages, :post, null: true, foreign_key: true
  end
end
