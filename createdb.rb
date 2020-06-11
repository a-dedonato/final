# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :courses do
  primary_key :id
  String :title
  String :course_code
  String :term
  String :professor
  String :meeting_pattern
  String :location
end
DB.create_table! :reviews do
  primary_key :id
  foreign_key :course_id
  foreign_key :user_id
  Integer :rating
  String :comments, text: true
end
DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :password
end

# Insert initial (seed) data
course_table = DB.from(:courses)

course_table.insert(title: "Finance I", 
                    course_code: "FINC-430",
                    term: "Fall 2019",
                    professor: "Prof. Darius Winkel",
                    meeting_pattern: "Mon/Thurs 1:30 pm - 3:00 pm",
                    location:"2211 Campus Dr, Evanston, IL 60208")

course_table.insert(title: "Leading in Organizations", 
                    course_code: "MORS-430",
                    term: "Winter 2019",
                    professor: "Prof. Elijah Davis",
                    meeting_pattern: "Tues/Fri 10:30 am - 12:00 pm",
                    location:"95 Merrick Way Coral Gables, Florida 33134")
