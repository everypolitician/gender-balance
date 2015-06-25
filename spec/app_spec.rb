require 'spec_helper'
require 'rack/test'

describe 'App' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  before do
    OmniAuth.config.test_mode = true
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

    it 'allows a user to sign in with twitter' do
      assert_difference 'User.count' do
        get '/auth/twitter'
        follow_redirect!
      end
      user = User.last
      assert_equal 'twitter', user.provider
      assert_equal '42', user.uid
      assert_equal 'Bob Test', user.name
    end
  end
end
