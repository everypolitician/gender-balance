require 'dotenv/tasks'
task app: :dotenv do
  require_relative './app'
end

namespace :db do
  desc 'Run migrations'
  task :migrate, [:version] => :app do |_t, args|
    require 'sequel'
    Sequel.extension :migration
    db = Sinatra::Application.database
    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(db, 'db/migrations', target: args[:version].to_i)
    else
      puts 'Migrating to latest'
      Sequel::Migrator.run(db, 'db/migrations')
    end
  end
end

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs << 'spec'
  t.test_files = FileList['spec/*_spec.rb']
  t.verbose = true
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new

task default: :test

namespace :cache do
  task country_person_counts: :app do
    countries_json = 'https://github.com/everypolitician/' \
      'everypolitician-data/raw/master/countries.json'
    countries = Yajl.load(open(countries_json).read, symbolize_keys: true)
    countries.each do |country|
      puts "Caching person count for #{country[:name]}"
      country_count = CountryCount.find_or_create(country_code: country[:code])
      counts = country[:legislatures].map { |l| l[:person_count] }
      country_count.person_count = counts.reduce(:+)
      country_count.save
    end
  end
end
