require 'spec_helper'

describe User do
  let(:auth) { { provider: 'twitter', uid: '123', info: { name: 'Alice' } } }
  let(:user) { User.create_with_omniauth(auth) }
  let(:australia) { Everypolitician.country(slug: 'Australia') }

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

  describe '#create_with_omniauth' do

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

  describe '#has_completed_onboarding?' do
    it 'is an alias for #completed_onboarding' do
      assert !user.has_completed_onboarding?
      user.completed_onboarding = true
      assert user.has_completed_onboarding?
    end
  end

  describe '#played_when_featured' do

    before do
      FeaturedCountry.current = australia.code
    end

    it "is false if user didn't play when featured" do
      assert !user.played_when_featured(australia)
    end

    it 'is true if the played played it while featured' do
      user.add_vote(person_uuid: 'au-1', choice: 'female')
      assert user.played_when_featured(australia)
    end

    it "is false if the country has never been featured" do
      assert !user.played_when_featured(Everypolitician.country(slug: 'Germany'))
    end
  end

  describe '#next_unfinished_term_for' do
    let(:representatives) { australia.legislature(slug: 'Representatives') }
    let(:term_44) { representatives.legislative_periods[0] }
    let(:term_43) { representatives.legislative_periods[1] }

    before do
      body44 = "id\nau-1\nau-2\n"
      stub_request(:get, term_44.csv_url).to_return(body: body44)
      body43 = "id\nau-3\nau-4\n"
      stub_request(:get, term_43.csv_url).to_return(body: body43)
    end

    describe 'with no user votes' do
      it 'returns the most recent term for the given legislature' do
        assert_equal term_44, user.next_unfinished_term_for(representatives)
      end
    end

    describe 'with user votes' do
      before do
        user.add_vote(person_uuid: 'au-1', choice: 'female')
        user.add_vote(person_uuid: 'au-2', choice: 'female')
      end

      it 'returns the most recent unfinished term' do
        assert_equal term_43, user.next_unfinished_term_for(representatives)
      end
    end

    describe 'with existing gender information' do
      before do
        CountryUUID.where(uuid: 'au-1').update(gender: 'female')
        CountryUUID.where(uuid: 'au-2').update(gender: 'female')
      end

      it 'returns the most recent unfinished term' do
        assert_equal term_43, user.next_unfinished_term_for(representatives)
      end
    end
  end

  describe '#record_vote' do
    it 'stores a vote for the user' do
      assert_difference 'user.votes_dataset.count' do
        user.record_vote(person_uuid: 'au-1', choice: 'female')
      end
    end

    it 'only records each vote once' do
      assert_difference 'user.votes_dataset.count' do
        3.times { user.record_vote(person_uuid: 'au-1', choice: 'female') }
      end
    end

    it 'updates the choice on subsequent votes' do
      user.record_vote(person_uuid: 'au-1', choice: 'male')
      user.record_vote(person_uuid: 'au-1', choice: 'female')
      assert_equal 'female', user.votes_dataset.first(person_uuid: 'au-1').choice
    end
  end

  describe '#votes_for_people' do
    before do
      user.add_vote(person_uuid: 'au-1', choice: 'female')
      user.add_vote(person_uuid: 'au-2', choice: 'female')
    end

    it 'returns a count of votes for the given gender' do
      assert_equal 0, user.votes_for_people([{ id: 'au-1' }, { id: 'au-2' }], 'male').count
      assert_equal 2, user.votes_for_people([{ id: 'au-1' }, { id: 'au-2' }], 'female').count
      assert_equal 0, user.votes_for_people([{ id: 'au-1' }, { id: 'au-2' }], ['foo', 'bar']).count
    end
  end

  describe '#remaining_counts' do
    let(:remaining) { user.remaining_counts.to_hash(:country_slug, :count) }

    describe 'with no votes' do
      it 'returns the total numbers for each country' do
        assert_equal({ 'Germany' => 3, 'Australia' => 3 }, remaining)
      end
    end

    describe 'with votes' do
      before do
        1.upto(3) { |n| user.add_vote(person_uuid: "au-#{n}", choice: 'female') }
        user.add_vote(person_uuid: 'de-1', choice: 'male')
      end

      it 'returns the remaining numbers for each country' do
        assert_equal({ 'Germany' => 2 }, remaining)
      end
    end
  end
end
