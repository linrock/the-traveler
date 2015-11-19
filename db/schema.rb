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

ActiveRecord::Schema.define(version: 20151118233755) do

  create_table "domains", force: :cascade do |t|
    t.string   "url",                           null: false
    t.boolean  "visited",       default: false
    t.boolean  "successful"
    t.string   "error_message"
    t.datetime "last_visit_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "domains", ["url"], name: "index_domains_on_url", unique: true
  add_index "domains", ["visited"], name: "index_domains_on_visited"

  create_table "favicon_snapshots", force: :cascade do |t|
    t.string   "query_url",   null: false
    t.string   "final_url"
    t.string   "favicon_url"
    t.integer  "flags"
    t.binary   "raw_data"
    t.binary   "png_data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "favicon_snapshots", ["query_url"], name: "index_favicon_snapshots_on_query_url"

end
