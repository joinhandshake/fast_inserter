ActiveRecord::Schema.define do
  self.verbose = false

  create_table "attendees", force: :cascade do |t|
    t.integer  "user_id",                            null: false
    t.integer  "attendable_id",                      null: false
    t.string   "attendable_type",                    null: false
    t.boolean  "checked_in",         default: false, null: false
    t.boolean  "registered",         default: false, null: false
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  create_table "events", force: :cascade do |t|
    t.string   "name",                                                                   null: false
    t.datetime "created_at",                                                             null: false
    t.datetime "updated_at",                                                             null: false
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
  end

  create_table "mass_email_emails", force: :cascade do |t|
    t.integer  "mass_email_id", null: false
    t.string   "email_address", null: false
    t.datetime "delivered_at"
  end

  create_table "mass_emails", force: :cascade do |t|
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "name"
  end
end
