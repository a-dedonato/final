# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "geocoder"                                                                    #
require "bcrypt"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

courses_table = DB.from(:courses)
reviews_table = DB.from(:reviews)
users_table = DB.from(:users)

# read your API credentials from environment variables
account_sid = ENV["TWILIO_ACCOUNT_SID"]
auth_token = ENV["TWILIO_AUTH_TOKEN"]

# set up a client to talk to the Twilio REST API
client = Twilio::REST::Client.new(account_sid, auth_token)

before do
    # SELECT * FROM users WHERE id = session[:user_id]
    @current_user = users_table.where(:id => session[:user_id]).to_a[0]
    puts @current_user.inspect
end

# Home page (all courses)
get "/" do
    # before stuff runs
    @courses = courses_table.all
    view "courses"
end

# Show a single course
get "/courses/:id" do
    @users_table = users_table
    # SELECT * FROM courses WHERE id=:id
    @course = courses_table.where(:id => params["id"]).to_a[0]
    # SELECT * FROM reviewss WHERE course_id=:id
    @reviews = reviews_table.where(:course_id => params["id"]).to_a
    # SELECT AVERAGE("rating") FROM reviews WHERE course_id=:id
    @rating = reviews_table.where(:course_id => params["id"]).avg(:rating).to_f
    view "course"
end

# Form to create a new review
get "/courses/:id/reviews/new" do
    @course = courses_table.where(:id => params["id"]).to_a[0]
    view "new_review"
end

# Receiving end of new review form
post "/courses/:id/reviews/create" do
    # if session[:user_id] =! nil
        reviews_table.insert(:course_id => params["id"],
                        :rating => params["rating"],
                        :user_id => @current_user[:id],
                        :comments => params["comments"])
        @course = courses_table.where(:id => params["id"]).to_a[0]
        # send the SMS from your trial Twilio number to your verified non-Twilio number
        client.messages.create(from: "+12057820554", to: "+16314870752", body: "Thank you for submitting a review!")
        view "create_review"
    # else
    #     view "not_logged_in"
end

# Form to create a new user
get "/users/new" do
    view "new_user"
end

# Receiving end of new user form
post "/users/create" do
    puts params.inspect
    users_table.insert(:name => params["name"],
                       :email => params["email"],
                       :password => BCrypt::Password.create(params["password"]))
    view "create_user"
end

# Form to login
get "/logins/new" do
    view "new_login"
end

# Receiving end of login form
post "/logins/create" do
    puts params
    email_entered = params["email"]
    password_entered = params["password"]
    # SELECT * FROM users WHERE email = email_entered
    user = users_table.where(:email => email_entered).to_a[0]
    if user
        puts user.inspect
        # test the password against the one in the users table
        if BCrypt::Password.new(user[:password]) == password_entered
            session[:user_id] = user[:id]
            view "create_login"
        else
            view "create_login_failed"
        end
    else 
        view "create_login_failed"
    end
end

# Logout
get "/logout" do
    session[:user_id] = nil
    view "logout"
end
