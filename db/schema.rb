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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140327111528) do

  create_table "atc_ratings", :force => true do |t|
    t.string   "name"
    t.integer  "priority"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0, :null => false
    t.integer  "attempts",   :default => 0, :null => false
    t.text     "handler",                   :null => false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "divisions", :force => true do |t|
    t.string   "name"
    t.integer  "priority"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "downloads", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
  end

  create_table "examinations", :force => true do |t|
    t.datetime "date"
    t.string   "departure_airport"
    t.string   "destination_airport"
    t.integer  "examiner_id"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
    t.integer  "rating_id"
  end

  create_table "examinations_pilots", :force => true do |t|
    t.integer "examination_id"
    t.integer "pilot_id"
  end

  create_table "examiners", :force => true do |t|
    t.string   "name"
    t.integer  "vatsimid"
    t.string   "email"
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
    t.boolean  "active",     :default => true
  end

  create_table "flight_briefings", :force => true do |t|
    t.string   "name"
    t.string   "departure"
    t.string   "destination"
    t.text     "description"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
  end

  create_table "instructors", :force => true do |t|
    t.string   "name"
    t.integer  "vatsimid"
    t.string   "email"
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
    t.boolean  "active",     :default => true
  end

  create_table "newbies", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.integer  "vatsimid"
    t.string   "country"
    t.string   "slug"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "newbies", ["slug"], :name => "index_newbies_on_slug", :unique => true

  create_table "options", :force => true do |t|
    t.string   "name"
    t.text     "value"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "pilot_files", :force => true do |t|
    t.integer  "user_id"
    t.integer  "pilot_id"
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
  end

  create_table "pilots", :force => true do |t|
    t.string   "name"
    t.integer  "rating_id"
    t.integer  "vatsimid"
    t.string   "email"
    t.string   "vacc"
    t.integer  "instructor_id"
    t.integer  "examination_id"
    t.integer  "atc_rating_id"
    t.integer  "division_id"
    t.boolean  "theory_passed",            :default => false
    t.boolean  "practical_passed",         :default => false
    t.boolean  "upgraded",                 :default => false
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
    t.boolean  "token_issued",             :default => false
    t.decimal  "theory_score"
    t.decimal  "practical_score"
    t.text     "notes"
    t.datetime "token_issued_date"
    t.datetime "theory_passed_date"
    t.datetime "practical_passed_date"
    t.datetime "upgraded_date"
    t.datetime "instructor_assigned_date"
    t.string   "slug"
    t.text     "examination_feedback"
    t.boolean  "token_reissued",           :default => false
    t.datetime "token_reissued_date"
    t.boolean  "ready_for_practical",      :default => false
    t.boolean  "theory_failed",            :default => false
    t.boolean  "practical_failed",         :default => false
    t.datetime "theory_failed_date"
    t.datetime "practical_failed_date"
    t.boolean  "contacted_by_email",       :default => false
    t.boolean  "theory_expired",           :default => false
  end

  add_index "pilots", ["slug"], :name => "index_pilots_on_slug", :unique => true

  create_table "pilots_trainings", :force => true do |t|
    t.integer "pilot_id"
    t.integer "training_id"
  end

  create_table "rails_admin_histories", :force => true do |t|
    t.text     "message"
    t.string   "username"
    t.integer  "item"
    t.string   "table"
    t.integer  "month",      :limit => 2
    t.integer  "year",       :limit => 8
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  add_index "rails_admin_histories", ["item", "table", "month", "year"], :name => "index_rails_admin_histories"

  create_table "ratings", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "priority"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "trainings", :force => true do |t|
    t.datetime "date"
    t.integer  "instructor_id"
    t.string   "departure_airport"
    t.string   "destination_airport"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
    t.text     "notes"
    t.integer  "rating_id"
    t.text     "description"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "",    :null => false
    t.string   "encrypted_password",     :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.string   "name"
    t.integer  "roles_mask"
    t.boolean  "has_cert_access",        :default => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
