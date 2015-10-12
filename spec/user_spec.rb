require 'spec_helper'

describe User do
  describe '#record_response' do
    let(:legislative_period) do
      LegislativePeriod.create(
        country_code: 'FOO',
        legislature_slug: '123',
        legislative_period_id: '123'
      )
    end
    subject { User.create(name: 'Test', uid: '123', provider: 'twitter') }

    it "shouldn't allow two responses for the same person" do
      subject.record_response(
        legislative_period_id: legislative_period.id,
        politician_id: 'alice',
        choice: 'female'
      )
      assert_equal 1, subject.responses_dataset.count
      5.times do
        subject.record_response(
          legislative_period_id: legislative_period.id,
          politician_id: 'bob',
          choice: 'male'
        )
      end
      assert_equal 2, subject.responses_dataset.count
    end
  end
end
