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
  set :motivational_quotes, YAML.load_file('config/motivational_quotes.yml')
end

require 'helpers'
require 'app/models'
require 'app/jobs'

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
  @leaders = Response.leaders
  if current_user
    erb :home_loggedin
  else
    erb :home_anonymous
  end
end

get '/login' do
  erb :login
end

get '/about' do
  erb :about
end

post '/event_handler' do
  settings.cache_client.delete('countries.json')
  UpdateCacheJob.perform_async
  'ok'
end

get '/logout' do
  session[:user_id] = nil
  flash[:notice] = 'You have been logged out'
  redirect to('/')
end

%w(get post).each do |method|
  send(method, '/auth/:provider/callback') do
    auth = request.env['omniauth.auth']
    user = User.first(provider: auth[:provider], uid: auth[:uid]) ||
           User.create_with_omniauth(auth)
    if session[:completed_onboarding]
      user.completed_onboarding = true
      user.save
    end
    session[:user_id] = user.id
    flash[:notice] = 'Signed in!'
    redirect to('/countries')
  end
end

get '/auth/failure' do
  logger.info "Auth failure: #{params[:message]}"
  flash[:notice] = "There was a problem authenticating you. Please try again."
  redirect '/login'
end

get '/onboarding' do
  redirect to('/countries') if completed_onboarding?
  erb :onboarding
end

get '/onboarding-complete' do
  session[:completed_onboarding] = true
  if current_user
    current_user.completed_onboarding = true
    current_user.save
  end
  redirect to('/countries')
end

before '/countries*' do
  redirect to('/onboarding') unless completed_onboarding?
  pass if current_user
  flash[:alert] = 'Please sign in'
  redirect to('/login')
end

get '/countries' do
  @countries = Country.all
  @recent_countries = current_user.responses_dataset.recent_countries
  current_featured_country = FeaturedCountry.current
  if current_featured_country
    @featured_country = Country.find_by_code(current_featured_country.country_code)
  end
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
  return erb :congratulations unless @legislative_period
  @people = current_user.people_for(@legislative_period)
  erb :term
end

get '/_stats' do
  @players = Response.join(:users, id: :user_id).group_and_count(:users__id)
  erb :stats
end

post '/responses' do
  begin
    current_user.record_response(params[:response])
    'ok'
  rescue Sequel::UniqueConstraintViolation
    halt 403, 'Decision already recorded for this politician'
  end
end

get '/export/:country_slug/:legislature_slug' do |country_slug, legislature_slug|
  content_type 'text/csv;charset=utf-8'
  country = Country.find_by_slug(country_slug)
  votes = Response
    .select(:politician_id, :user_id, :choice)
    .join(:legislative_periods, legislative_periods__id: :responses__legislative_period_id)
    .where(country_code: country[:code], legislature_slug: legislature_slug)
    .order(:responses__created_at)
  counts = {}

  # This is purposely overwriting earlier votes by a user with later ones so
  # that we only count one vote for a politician per user.
  votes.each do |row|
    counts[row[:politician_id]] ||= {}
    counts[row[:politician_id]][row[:user_id]] = row[:choice]
  end
  headers = ['uuid', 'female', 'male', 'other', 'skip']
  rows = counts.map do |politician_id, per_person_votes|
    v = Hash[per_person_votes.values.group_by { |t| t }.map { |t, c| [t, c.size] }]
    [politician_id, v['female'], v['male'], v['other'], v['skip']]
  end
  CSV.generate do |csv|
    csv << headers
    rows.each { |row| csv << row }
  end
end
