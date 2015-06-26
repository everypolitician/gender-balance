require 'spec_helper'

describe Response do
  let(:user) { User.create(name: 'Bob Test', uid: '42', provider: 'twitter') }

  it 'has a restricted set of choices' do
    response = Response.new(
      user_id: user.id,
      politician_id: 1,
      legislative_period_id: 1,
      legislature_slug: 'uk',
      choice: 'male'
    )
    assert response.valid?
    response.choice = 'foo'
    assert !response.valid?
  end
end
