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

ActiveRecord::Schema.define(version: 20160501191459) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "layers", force: :cascade do |t|
    t.integer  "api_id"
    t.string   "name"
    t.string   "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "stacks", force: :cascade do |t|
    t.integer  "api_id"
    t.string   "name"
    t.string   "slug"
    t.integer  "popularity"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.hstore   "full_object"
  end

  create_table "stacks_tags", force: :cascade do |t|
    t.integer "stack_id"
    t.integer "tag_id"
  end

  add_index "stacks_tags", ["stack_id"], name: "index_stacks_tags_on_stack_id", using: :btree
  add_index "stacks_tags", ["tag_id"], name: "index_stacks_tags_on_tag_id", using: :btree

  create_table "stacks_tools", force: :cascade do |t|
    t.integer "stack_id"
    t.integer "tool_id"
  end

  add_index "stacks_tools", ["stack_id"], name: "index_stacks_tools_on_stack_id", using: :btree
  add_index "stacks_tools", ["tool_id"], name: "index_stacks_tools_on_tool_id", using: :btree

  create_table "tags", force: :cascade do |t|
    t.string   "name"
    t.integer  "api_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tools", force: :cascade do |t|
    t.integer  "layer_id"
    t.integer  "api_id"
    t.string   "name"
    t.string   "slug"
    t.integer  "popularity"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.hstore   "full_object"
  end

  add_index "tools", ["layer_id"], name: "index_tools_on_layer_id", using: :btree

  add_foreign_key "stacks_tags", "stacks"
  add_foreign_key "stacks_tags", "tags"
  add_foreign_key "stacks_tools", "stacks"
  add_foreign_key "stacks_tools", "tools"
  add_foreign_key "tools", "layers"
end
