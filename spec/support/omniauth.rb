OmniAuth.config.test_mode = true

OmniAuth.config.mock_auth[:twitter] = OmniAuth::AuthHash.new(
  provider: 'twitter',
  uid: '123545',
  info: {
    name: 'Bob Test'
  },
  credentials: {
    token: 'abc123'
  }
)
