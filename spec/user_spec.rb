require 'spec_helper'

describe User do
  describe '#create_with_omniauth' do
    let(:auth) { { provider: 'twitter', uid: '123', info: { name: 'Alice' } } }

    it 'creates a user with the provided info' do
      user = User.create_with_omniauth(auth)
      assert_equal 'twitter', user.provider
      assert_equal '123', user.uid
      assert_equal 'Alice', user.name
    end

    it 'uses the nickname if name is missing' do
      user = User.create_with_omniauth(auth.merge(info: { nickname: 'a1ice' }))
      assert_equal 'a1ice', user.name
    end

    it 'uses the email if name and nickname are missing' do
      user = User.create_with_omniauth(auth.merge(info: { email: 'alice@example.org' }))
      assert_equal 'alice@example.org', user.name
    end
  end

  describe '#recent_countries' do
    let(:auth) { { provider: 'twitter', uid: '123', info: { name: 'Alice' } } }
    let(:user) { User.create_with_omniauth(auth) }

    before do
      1.upto(3) do |n|
        CountryUUID.create(
          country_slug: 'Australia',
          legislature_slug: 'Senate',
          uuid: "au-#{n}"
        )
        CountryUUID.create(
          country_slug: 'Germany',
          legislature_slug: 'Bundestag',
          uuid: "de-#{n}"
        )
      end
    end

    it 'includes countries a user has voted for' do
      user.add_vote(person_uuid: 'au-1', choice: 'female')
      user.add_vote(person_uuid: 'de-1', choice: 'male')
      assert_equal ['Germany', 'Australia'], user.recent_countries.map(&:name)
    end

    it "doesn't include completed countries" do
      user.add_vote(person_uuid: 'de-1', choice: 'male')
      user.add_vote(person_uuid: 'au-1', choice: 'female')
      user.add_vote(person_uuid: 'au-2', choice: 'female')
      user.add_vote(person_uuid: 'au-3', choice: 'female')
      assert_equal ['Germany'], user.recent_countries.map(&:name)
    end
  end
end
