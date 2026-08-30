# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_30_130100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vector"

  create_table "answers", force: :cascade do |t|
    t.text "body"
    t.integer "cited_document_ids", default: [], null: false, array: true
    t.decimal "cost_usd", precision: 12, scale: 8, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.integer "input_tokens", default: 0, null: false
    t.integer "knowledge_version", null: false
    t.integer "latency_ms", default: 0, null: false
    t.string "model"
    t.integer "output_tokens", default: 0, null: false
    t.text "question", null: false
    t.vector "question_embedding", limit: 384, null: false
    t.string "rung", null: false
    t.string "rungs_tried", default: [], null: false, array: true
    t.datetime "updated_at", null: false
    t.index ["knowledge_version", "question"], name: "index_answers_on_knowledge_version_and_question"
    t.check_constraint "rung::text = ANY (ARRAY['0'::character varying, '1'::character varying, '2'::character varying, '3'::character varying, 'handoff'::character varying]::text[])", name: "answers_rung_check"
  end

  create_table "chunks", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "document_id", null: false
    t.vector "embedding", limit: 384, null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id", "position"], name: "index_chunks_on_document_id_and_position", unique: true
    t.index ["document_id"], name: "index_chunks_on_document_id"
  end

  create_table "corpus_state", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "knowledge_version", default: 0, null: false
    t.datetime "updated_at", null: false
  end

  create_table "documents", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.string "path", null: false
    t.bigint "project_id", null: false
    t.string "sha", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["path"], name: "index_documents_on_path", unique: true
    t.index ["project_id"], name: "index_documents_on_project_id"
    t.check_constraint "kind::text = ANY (ARRAY['adr'::character varying, 'readme'::character varying, 'note'::character varying]::text[])", name: "documents_kind_check"
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_projects_on_name", unique: true
  end

  add_foreign_key "chunks", "documents"
  add_foreign_key "documents", "projects"
end
