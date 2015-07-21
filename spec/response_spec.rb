require 'spec_helper'
require 'date'

describe Response do
  let(:user) { User.create(name: 'Bob Test', uid: '42', provider: 'twitter') }
  let(:legislative_period) { LegislativePeriod.create(country_code: 'ABC', legislature_slug: 'abc', legislative_period_id: 2, start_date: Date.new(2010)) }

  it 'has a restricted set of choices' do
    response = Response.new(
      user_id: user.id,
      politician_id: 1,
      legislative_period_id: legislative_period.id,
      choice: 'male'
    )
    assert response.valid?
    response.choice = 'foo'
    assert !response.valid?
  end
end
