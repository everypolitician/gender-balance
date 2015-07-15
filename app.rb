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

get '/event_handler' do
  expire('countries.json')
  'ok'
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
    redirect to('/')
  end
end

get '/auth/failure' do
  flash[:notice] = params[:message]
  redirect '/'
end

before '/countries*' do
  pass if current_user
  flash[:alert] = 'Please sign in'
  redirect to('/')
end

get '/countries' do
  @countries = countries
  recent_country_codes = current_user.responses_dataset
                         .distinct(:country_code)
                         .order(:country_code, Sequel.desc(:created_at))
                         .limit(5)
                         .map(&:country_code)
  @recent = countries.select { |c| recent_country_codes.include?(c[:code]) }
  erb :countries
end

get '/countries/:country' do
  @country = countries.find { |c| c[:slug] == params[:country] }
  erb :country
end

get '/countries/:country/legislatures/:legislature/periods/:period/person' do
  @country = countries.find { |c| c[:slug] == params[:country] }
  @legislature = @country[:legislatures].find { |l| l[:slug] == params[:legislature] }
  @legislative_period = @legislature[:legislative_periods].find { |lp| lp[:slug] == params[:period] }
  @people = csv_for(@legislature[:sha], @legislative_period[:csv], @legislature[:lastmod])
  already_done = current_user.responses_dataset.select(:politician_id).where(
    country_code: @country[:code],
    legislature_slug: @legislature[:slug]
  ).map(&:politician_id)
  @people = @people.reject { |person| already_done.include?(person[:id]) }
  @people = @people.reject { |person| person[:gender] }
  @people.shuffle!
  erb :person
end

post '/responses' do
  begin
    current_user.add_response(params[:response])
    'ok'
  rescue Sequel::UniqueConstraintViolation
    halt 403, 'Decision already recorded for this politician'
  end
end
