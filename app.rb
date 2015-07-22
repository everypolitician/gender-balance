require 'bundler'
Bundler.require
Dotenv.load

require 'tilt/erubis'
require 'tilt/sass'
require 'active_support/core_ext'
require 'open-uri'
require 'csv'

$LOAD_PATH << File.expand_path('../lib', __FILE__)
$LOAD_PATH << File.expand_path('../', __FILE__)

configure do
  set :sessions, expire_after: 5.years
  set :session_secret, ENV['SESSION_SECRET']
  set :database, lambda {
    ENV['DATABASE_URL'] ||
      "postgres:///gender_crowdsourcing_#{environment}"
  }
  set :cache_client, Dalli::Client.new(
    (ENV['MEMCACHIER_SERVERS'] || 'localhost:11211').split(','),
    username: ENV['MEMCACHIER_USERNAME'],
    password: ENV['MEMCACHIER_PASSWORD'],
    failover: true,
    socket_timeout: 1.5,
    socket_failure_delay: 0.2
  )
  set :static_cache_control, [:public, max_age: 5.minutes] if production?
end

require 'helpers'
require 'app/models'

helpers Helpers

use Rack::Flash

use OmniAuth::Builder do
  provider :twitter, ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET']
  provider :facebook, ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_APP_SECRET']
  provider :github, ENV['GITHUB_CLIENT_ID'], ENV['GITHUB_CLIENT_SECRET']
  provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET']
  provider :linkedin, ENV['LINKEDIN_CLIENT_ID'], ENV['LINKEDIN_CLIENT_SECRET']
end

get '/*.css' do |filename|
  cache_control :public, max_age: 5.minutes if settings.production?
  scss :"sass/#{filename}"
end

get '/' do
  erb :index
end

get '/login' do
  erb :login
end

get '/about' do
  erb :about
end

%w(get post).each do |method|
  send(method, '/event_handler') do
    settings.cache_client.delete('countries.json')
    'ok'
  end
end

get '/logout' do
  session.clear
  flash[:notice] = 'You have been logged out'
  redirect to('/')
end

%w(get post).each do |method|
  send(method, '/auth/:provider/callback') do
    auth = request.env['omniauth.auth']
    user = User.first(provider: auth[:provider], uid: auth[:uid]) ||
           User.create_with_omniauth(auth)
    session[:user_id] = user.id
    flash[:notice] = 'Signed in!'
    redirect to('/countries')
  end
end

get '/auth/failure' do
  flash[:notice] = params[:message]
  redirect '/'
end

get '/onboarding' do
  erb :onboarding
end

before '/countries*' do
  pass if current_user
  flash[:alert] = 'Please sign in'
  redirect to('/login')
end

get '/countries' do
  @countries = Country.all
  @recent_countries = current_user.responses_dataset.recent_countries
  erb :countries
end

get '/countries/:country' do
  @country = Country.find_by_slug(params[:country])
  if @country[:legislatures].length == 1
    legislature = @country[:legislatures].first
    redirect to("/countries/#{@country[:slug]}/legislatures/#{legislature[:slug]}")
  else
    erb :country
  end
end

get '/countries/:country/legislatures/:legislature' do
  @country = Country.find_by_slug(params[:country])
  @legislature = @country.legislature(params[:legislature])
  @legislative_period = current_user.legislative_period_for(@country, @legislature)
  if @legislative_period
    @people = current_user.people_for(@legislative_period)
    erb :term
  else
    erb :congratulations
  end
end

post '/responses' do
  begin
    current_user.add_response(params[:response])
    'ok'
  rescue Sequel::UniqueConstraintViolation
    halt 403, 'Decision already recorded for this politician'
  end
end
