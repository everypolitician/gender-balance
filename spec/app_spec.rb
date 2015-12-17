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
        assert last_response.body.include?('There was a problem authenticating you. Please try again.')
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

  describe 'CSV API' do
    let(:user) { User.create(name: 'Bob Test', uid: '42', provider: 'twitter') }
    let(:legislative_period) { LegislativePeriod.create(country_code: 'AU', legislature_slug: 'Senate', legislative_period_id: 2, start_date: Date.new(2010)) }

    before do
      %w(male male female).each_with_index do |choice, i|
        Response.create(
          user_id: user.id,
          politician_id: "pol#{i}",
          legislative_period_id: legislative_period.id,
          choice: choice
        )
      end
    end

    describe 'simple download' do
      before do
        get '/export/Australia/Senate'
      end

      it 'returns a success status code' do
        assert_equal 200, last_response.status
      end

      it 'has the correct content type' do
        assert_equal 'text/csv;charset=utf-8', last_response.header['content-type']
      end

      it 'returns the correct CSV' do
        response = CSV.parse(last_response.body, headers: true)
        assert_equal ["politician_id", "female", "male", "other", "skip"], response.headers
        expected = [
          {"politician_id"=>"pol0", "female"=>nil, "male"=>"1", "other"=>nil, "skip"=>nil},
          {"politician_id"=>"pol1", "female"=>nil, "male"=>"1", "other"=>nil, "skip"=>nil},
          {"politician_id"=>"pol2", "female"=>"1", "male"=>nil, "other"=>nil, "skip"=>nil}
        ]
        assert_equal expected, response.map(&:to_hash)
      end

      describe 'with duplicate responses' do
        before do
          Response.create(
            user_id: user.id,
            politician_id: "pol1",
            legislative_period_id: legislative_period.id,
            choice: 'skip'
          )
          get '/export/Australia/Senate'
        end

        it "doesn't count votes twice" do
          response = CSV.parse(last_response.body, headers: true)
          expected = [
            {"politician_id"=>"pol0", "female"=>nil, "male"=>"1", "other"=>nil, "skip"=>nil},
            {"politician_id"=>"pol1", "female"=>nil, "male"=>nil, "other"=>nil, "skip"=>"1"},
            {"politician_id"=>"pol2", "female"=>"1", "male"=>nil, "other"=>nil, "skip"=>nil}
          ]
          assert_equal expected, response.map(&:to_hash)
        end
      end
    end
  end
end
