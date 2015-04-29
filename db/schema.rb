# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150424140231) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "advocates", force: true do |t|
    t.integer  "chamber_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "advocates", ["chamber_id"], name: "index_advocates_on_chamber_id", using: :btree

  create_table "case_worker_claims", force: true do |t|
    t.integer  "case_worker_id"
    t.integer  "claim_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "case_worker_claims", ["case_worker_id"], name: "index_case_worker_claims_on_case_worker_id", using: :btree
  add_index "case_worker_claims", ["claim_id"], name: "index_case_worker_claims_on_claim_id", using: :btree

  create_table "case_workers", force: true do |t|
    t.string   "role"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "case_workers", ["role"], name: "index_case_workers_on_role", using: :btree

  create_table "chambers", force: true do |t|
    t.string   "name"
    t.string   "supplier_no"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "chambers", ["name"], name: "index_chambers_on_name", using: :btree
  add_index "chambers", ["supplier_no"], name: "index_chambers_on_supplier_no", using: :btree

  create_table "claims", force: true do |t|
    t.text     "additional_information"
    t.boolean  "vat_required"
    t.string   "state"
    t.string   "case_type"
    t.datetime "submitted_at"
    t.string   "case_number"
    t.decimal  "fees_total",             default: 0.0
    t.decimal  "expenses_total",         default: 0.0
    t.decimal  "total",                  default: 0.0
    t.integer  "advocate_id"
    t.integer  "court_id"
    t.integer  "offence_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "claims", ["advocate_id"], name: "index_claims_on_advocate_id", using: :btree
  add_index "claims", ["court_id"], name: "index_claims_on_court_id", using: :btree
  add_index "claims", ["offence_id"], name: "index_claims_on_offence_id", using: :btree

  create_table "courts", force: true do |t|
    t.string   "code"
    t.string   "name"
    t.string   "court_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "courts", ["code"], name: "index_courts_on_code", using: :btree
  add_index "courts", ["court_type"], name: "index_courts_on_court_type", using: :btree
  add_index "courts", ["name"], name: "index_courts_on_name", using: :btree

  create_table "defendants", force: true do |t|
    t.string   "first_name"
    t.string   "middle_name"
    t.string   "last_name"
    t.datetime "date_of_birth"
    t.datetime "representation_order_date"
    t.boolean  "order_for_judicial_apportionment"
    t.string   "maat_reference"
    t.integer  "claim_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "defendants", ["claim_id"], name: "index_defendants_on_claim_id", using: :btree

  create_table "document_types", force: true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "documents", force: true do |t|
    t.integer  "claim_id"
    t.integer  "document_type_id"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "document_file_name"
    t.string   "document_content_type"
    t.integer  "document_file_size"
    t.datetime "document_updated_at"
  end

  add_index "documents", ["claim_id"], name: "index_documents_on_claim_id", using: :btree
  add_index "documents", ["document_file_name"], name: "index_documents_on_document_file_name", using: :btree
  add_index "documents", ["document_type_id"], name: "index_documents_on_document_type_id", using: :btree

  create_table "expense_types", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "expense_types", ["name"], name: "index_expense_types_on_name", using: :btree

  create_table "expenses", force: true do |t|
    t.integer  "expense_type_id"
    t.integer  "claim_id"
    t.datetime "date"
    t.string   "location"
    t.integer  "quantity"
    t.decimal  "rate"
    t.decimal  "hours"
    t.decimal  "amount"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "expenses", ["claim_id"], name: "index_expenses_on_claim_id", using: :btree
  add_index "expenses", ["expense_type_id"], name: "index_expenses_on_expense_type_id", using: :btree

  create_table "features", force: true do |t|
    t.string   "key",                        null: false
    t.boolean  "enabled",    default: false, null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "fee_categories", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fee_categories", ["name"], name: "index_fee_categories_on_name", using: :btree

  create_table "fee_types", force: true do |t|
    t.string   "description"
    t.string   "code"
    t.integer  "fee_category_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fee_types", ["code"], name: "index_fee_types_on_code", using: :btree
  add_index "fee_types", ["description"], name: "index_fee_types_on_description", using: :btree
  add_index "fee_types", ["fee_category_id"], name: "index_fee_types_on_fee_category_id", using: :btree

  create_table "fees", force: true do |t|
    t.integer  "claim_id"
    t.integer  "fee_type_id"
    t.integer  "quantity"
    t.decimal  "rate"
    t.decimal  "amount"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fees", ["claim_id"], name: "index_fees_on_claim_id", using: :btree
  add_index "fees", ["fee_type_id"], name: "index_fees_on_fee_type_id", using: :btree

  create_table "offences", force: true do |t|
    t.string   "description"
    t.string   "offence_class"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.integer  "persona_id"
    t.string   "persona_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
