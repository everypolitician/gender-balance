class CountryUUID < Sequel::Model
  dataset_module do
    def recent_countries_for(user)
      total_people = CountryUUID.select{count(:*){}}.where(country_slug: :u__country_slug)
      from(:country_uuids___u)
        .select_group(:country_slug)
        .select_append{max(votes__created_at).as(:last_vote)}
        .select_append(Sequel.function(:count).*.as(:votes))
        .select_append(total_people.as(:total_people))
        .join(:votes, person_uuid: :uuid)
        .where(user_id: user.id)
        .having('count(*) < ?', total_people)
        .order(Sequel.desc(:last_vote))
        .limit(5)
    end

    def totals
      select(
        :country_slug,
        votes_for(:female),
        votes_for(:male),
        votes_for(:other),
        votes_for(:skip),
        Sequel.function(:count, :gender).as(:known),
        Sequel.function(:count).*.as(:total)
      )
      .group(:country_slug)
      .order(:country_slug)
    end

    private

    def votes_for(gender)
      Sequel.function(:count, Sequel.case({ gender.to_s => 1 }, nil, :gender)).as(gender)
    end
  end
end
