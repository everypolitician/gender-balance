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
end
