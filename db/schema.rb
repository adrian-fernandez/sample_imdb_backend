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

ActiveRecord::Schema.define(version: 20161222082428) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "actors", force: :cascade do |t|
    t.string "imdb_id", null: false
    t.string "name"
    t.string "photo"
  end

  add_index "actors", ["imdb_id"], name: "index_actors_on_imdb_id", unique: true, using: :btree

  create_table "directors", force: :cascade do |t|
    t.string "name"
  end

  create_table "movies", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "imdb_id",     limit: 9,              null: false
    t.string   "title"
    t.integer  "director_id"
    t.string   "actor_ids",             default: [],              array: true
    t.integer  "year"
    t.float    "rate"
    t.string   "poster"
  end

  add_index "movies", ["actor_ids"], name: "index_movies_on_actor_ids", using: :btree
  add_index "movies", ["director_id"], name: "index_movies_on_director_id", using: :btree
  add_index "movies", ["imdb_id"], name: "index_movies_on_imdb_id", unique: true, using: :btree
  add_index "movies", ["title"], name: "index_movies_on_title", unique: true, using: :btree

  create_table "users", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "username"
    t.string   "password"
    t.string   "password_digest"
    t.string   "token",           limit: 256
  end

end
