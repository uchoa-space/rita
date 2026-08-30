class CreateChatThreadsAndMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_threads do |t|
      t.string :status, null: false, default: "open"
      t.timestamps
    end
    add_check_constraint :chat_threads, "status IN ('open', 'closed')", name: "chat_threads_status_check"

    create_table :messages do |t|
      t.references :thread, null: false, foreign_key: { to_table: :chat_threads }
      t.string :role, null: false
      t.text :body
      t.references :answer, null: true, foreign_key: true
      t.string :failure_code
      t.string :failure_message
      t.timestamps
    end
    add_check_constraint :messages, "role IN ('user', 'assistant')", name: "messages_role_check"
    add_check_constraint :messages, "body IS NOT NULL OR failure_code IS NOT NULL", name: "messages_body_or_failure_check"
  end
end
