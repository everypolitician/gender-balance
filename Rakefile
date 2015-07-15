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

namespace :results do
  MINIMUM_VOTES = 5
  desc 'print results'
  task print: :app do
    responses = Response.with_votes(MINIMUM_VOTES)
    abort 'Nothing found' if responses.empty?
    responses.each do |response|
      p response if response.no_conflicts?
    end
  end
end
