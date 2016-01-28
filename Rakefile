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

task cache: ['cache:country_person_counts', 'cache:legislative_periods']

namespace :cache do
  task country_person_counts: :app do
    UpdateCacheJob.new.cache_country_person_counts
  end

  task legislative_periods: :app do
    UpdateCacheJob.new.cache_legislative_periods
  end
end

task add_country_slug_to_featured_countries: :app do
  FeaturedCountry.each do |fc|
    country = Everypolitician.country(code: fc.country_code)
    fc.update(country_slug: country.slug)
  end
end
