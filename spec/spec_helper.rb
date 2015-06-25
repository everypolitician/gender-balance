ENV['RACK_ENV'] = 'test'

require 'simplecov'
SimpleCov.start if ENV['COVERAGE']

require 'minitest/autorun'
require_relative '../app'

Dir['spec/support/**/*.rb'].each { |f| require f }
