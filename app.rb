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

get '/event_handler' do
  settings.cache_client.delete('countries.json')
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
  @countries = countries
  recent_country_codes = current_user.responses_dataset.recent_country_codes
  @recent = countries.select { |c| recent_country_codes.include?(c[:code]) }
  erb :countries
end

get '/countries/:country' do
  @country = countries.find { |c| c[:slug] == params[:country] }
  if @country[:legislatures].length == 1
    legislature = @country[:legislatures].first
    redirect to("/countries/#{@country[:slug]}/legislatures/#{legislature[:slug]}")
  else
    erb :country
  end
end

get '/countries/:country/legislatures/:legislature' do
  @country = countries.find { |c| c[:slug] == params[:country] }
  @legislature = @country[:legislatures].find { |l| l[:slug] == params[:legislature] }
  last_vote = current_user.responses_dataset.join(:legislative_periods, id: :legislative_period_id).order(:start_date).first
  last_legislative_period = LegislativePeriod.first(legislative_period_id: last_vote.legislative_period_id)
  if last_legislative_period.person_count == current_user.responses_dataset.where(legislative_period_id: last_legislative_period.id).count
    # User has finished this term, move onto the next
    legislative_period_index = @legislature[:legislative_periods].index { |lp| lp[:id] == last_legislative_period.legislative_period_id }
    @legislative_period = @legislature[:legislative_periods][legislative_period_index + 1]
  else
    # User is in the middle of this term, show it
    @legislative_period = @legislature[:legislative_periods].find { |lp| lp[:id] == last_legislative_period.legislative_period_id }
  end
  @people = csv_for(@legislature[:sha], @legislative_period[:csv], @legislature[:lastmod])
  already_done = current_user.responses_dataset.join(:legislative_periods, id: :legislative_period_id).select(:politician_id).where(
    country_code: @country[:code],
    legislature_slug: @legislature[:slug]
  ).map(&:politician_id)
  @total = @people.size
  @people = @people.reject { |person| already_done.include?(person[:id]) }
  @people = @people.reject { |person| person[:gender] }
  @people.shuffle!
  erb :term
end

post '/responses' do
  begin
    response = params[:response]
    legislative_period = LegislativePeriod.first(
      country_code: response[:country_code],
      legislature_slug: response[:legislature_slug],
      legislative_period_id: response[:legislative_period_id]
    )
    current_user.add_response(
      politician_id: response[:politician_id],
      choice: response[:choice],
      legislative_period_id: legislative_period.id
    )
    'ok'
  rescue Sequel::UniqueConstraintViolation
    halt 403, 'Decision already recorded for this politician'
  end
end
