require 'spec_helper'
require 'rack/test'

describe 'App' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.logger = Logger.new('/dev/null')
    OmniAuth.config.mock_auth[:twitter] = nil
  end

  it 'has a homepage' do
    get '/'
    assert last_response.ok?
  end

  describe 'auth' do
    before do
      OmniAuth.config.mock_auth[:twitter] = OmniAuth::AuthHash.new(
        provider: 'twitter',
        uid: '42',
        info: {
          name: 'Bob Test'
        }
      )
    end

    describe 'sign in with twitter' do
      it "creates a new user if one doesn't exist" do
        assert_difference 'User.count' do
          get '/auth/twitter'
          follow_redirect!
        end
        user = User.last
        assert_equal 'twitter', user.provider
        assert_equal '42', user.uid
        assert_equal 'Bob Test', user.name
      end

      it "doesn't create a user if one already exists" do
        User.create(
          provider: 'twitter',
          uid: '42',
          name: 'Existing User'
        )
        assert_difference 'User.count', 0 do
          get '/auth/twitter'
          follow_redirect!
        end
      end

      it 'shows the user a message if login fails' do
        OmniAuth.config.mock_auth[:twitter] = :invalid_credentials
        get '/auth/twitter'
        3.times { follow_redirect! }
        assert last_response.body.include?('invalid_credentials')
      end
    end

    describe 'logout' do
      it 'redirects home with flash notice' do
        get '/logout'
        follow_redirect!
        assert last_response.body.include?('You have been logged out')
      end
    end
  end
end
