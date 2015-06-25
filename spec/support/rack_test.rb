require 'rack/test'

class Minitest::Spec
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end
end
