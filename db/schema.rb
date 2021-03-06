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

ActiveRecord::Schema.define(version: 20131117144255) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "episodes", force: true do |t|
    t.string   "title"
    t.text     "description"
    t.string   "url"
    t.string   "image"
    t.datetime "pubdate"
    t.string   "guid"
    t.integer  "source_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "episodes", ["source_id", "guid"], name: "episode_uniq_guid", unique: true, using: :btree
  add_index "episodes", ["source_id"], name: "index_episodes_on_source_id", using: :btree

  create_table "opml_files", force: true do |t|
    t.text     "source"
    t.integer  "owner_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "md5"
  end

  add_index "opml_files", ["md5", "owner_id"], name: "index_opml_files_on_md5_and_owner_id", using: :btree
  add_index "opml_files", ["owner_id"], name: "index_opml_files_on_owner_id", using: :btree

  create_table "opml_files_sources", id: false, force: true do |t|
    t.integer "opml_file_id"
    t.integer "source_id"
  end

  add_index "opml_files_sources", ["opml_file_id", "source_id"], name: "opml_files_sources_index", unique: true, using: :btree

  create_table "owners", force: true do |t|
    t.string   "token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "image"
  end

  add_index "owners", ["token"], name: "index_owners_on_token", unique: true, using: :btree

  create_table "sources", force: true do |t|
    t.string   "url"
    t.string   "title"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "image"
    t.boolean  "offline"
    t.boolean  "active"
  end

  add_index "sources", ["active"], name: "index_sources_on_active", using: :btree
  add_index "sources", ["url"], name: "index_sources_on_url", unique: true, using: :btree

end
