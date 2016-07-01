require 'bundler'
Bundler.require
Dotenv.load

require 'tilt/erubis'
require 'tilt/sass'
require 'active_support/core_ext'
require 'open-uri'
require 'json'
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
  set :static_cache_control, [:public, max_age: 5.minutes] if production?
  set :motivational_quotes, YAML.load_file('config/motivational_quotes.yml')
end

require 'helpers'
require 'app/models'
require 'app/jobs'
require 'csv_export'
require 'country_proxy'
require 'reports'

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
  @leaders = Vote.leaders
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
  # This forces the Everypolitician class to refetch countries.json next
  # time it's accessed.
  Everypolitician.countries = nil
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
  country_counts = CountryUUID.totals.to_hash(:country_slug)
  user_counts = current_user.votes_dataset.country_counts.to_hash(:country_slug, :count)
  remaining_counts = current_user.remaining_counts.to_hash(:country_slug, :count)
  @countries = Everypolitician.countries.map do |country|
    CountryProxy.new(country, country_counts[country.slug], user_counts[country.slug], remaining_counts[country.slug])
  end
  @recent_countries = current_user.recent_countries.map do |country|
    CountryProxy.new(country, country_counts[country.slug], user_counts[country.slug], remaining_counts[country.slug])
  end
  current_featured_country = FeaturedCountry.current
  if current_featured_country
    @featured_country = CountryProxy.new(
      Everypolitician.country(code: current_featured_country.country_code),
      country_counts[current_featured_country.country_slug],
      user_counts[current_featured_country.country_slug],
      remaining_counts[current_featured_country.country_slug]
    )
  end
  erb :countries
end

get '/countries/:country' do
  @country = Everypolitician.country(slug: params[:country])
  if @country.legislatures.length == 1
    legislature = @country.legislatures.first
    redirect to("/countries/#{@country.slug}/legislatures/#{legislature.slug}")
  else
    erb :country
  end
end

get '/countries/:country/legislatures/:legislature' do
  @country = Everypolitician.country(slug: params[:country])
  @legislature = @country.legislature(slug: params[:legislature])
  country_count = CountryUUID.totals.first(country_slug: params[:country])
  halt erb(:no_data_needed) if country_count[:total] == country_count[:known]
  @legislative_period = current_user.next_unfinished_term_for(@legislature)
  halt erb(:congratulations) unless @legislative_period
  @all_people = @legislative_period.csv.map(&:to_hash).uniq { |p| p[:id] }.reject { |p| p[:gender] }
  @male_total = current_user.votes_for_people(@all_people, 'male').count
  @female_total = current_user.votes_for_people(@all_people, 'female').count
  @other_total = current_user.votes_for_people(@all_people, %w[other skip]).count
  already_done = current_user.votes_dataset.map(:person_uuid)
  @people = @all_people.reject { |person| already_done.include?(person[:id]) }.shuffle
  halt erb(:congratulations) if @people.empty?
  erb :term
end

get '/reports/:country' do
  redirect to('/login') unless current_user
  @country = Everypolitician.country(slug: params[:country])
  stats_raw = JSON.parse(open('https://everypolitician.github.io/gender-balance-country-stats/stats.json').read, symbolize_names: true)
  stats = Hash[stats_raw.map { |c| [c[:slug], c] }]
  @country_stats = stats[params[:country]]
  @legislature_stats = Hash[@country_stats[:legislatures].map {|l| [l[:slug], l]}]
  @legislatures = @country.legislatures.map { |l| Reports::LegislatureReport.new(l, @legislature_stats[l.slug]) }
  erb :report, :layout => :layout_page
end

get '/_stats' do
  @players = Vote.join(:users, id: :user_id).group_and_count(:users__id)
  erb :stats
end

post '/votes' do
  begin
    current_user.record_vote(params[:vote])
    'ok'
  rescue Sequel::UniqueConstraintViolation
    halt 403, 'Decision already recorded for this politician'
  end
end

get '/export/:country_slug/:legislature_slug' do |country_slug, legislature_slug|
  content_type 'text/csv;charset=utf-8'
  CsvExport.new(country_slug, legislature_slug).to_csv
end
