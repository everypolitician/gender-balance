# Represents a user created from a social login.
class User < Sequel::Model
  one_to_many :responses
  one_to_many :votes

  def self.create_with_omniauth(auth)
    create do |user|
      user.provider = auth[:provider]
      user.uid = auth[:uid]
      user.name = auth[:info][:name] ||
        auth[:info][:nickname] ||
        auth[:info][:email]
    end
  end

  def recent_countries
    CountryUUID.recent_countries_for(self).map do |c|
      Everypolitician.country(slug: c.country_slug)
    end
  end

  def has_completed_onboarding?
    completed_onboarding
  end

  def played_when_featured(country)
    featured_country = FeaturedCountry.first(country_slug: country.slug)
    return false if featured_country.nil?
    votes_dataset
      .join(:country_uuids, uuid: :person_uuid)
      .where(country_slug: country.slug)
      .where{votes__created_at > featured_country.start_date}
      .where{votes__created_at < featured_country.end_date}
      .any?
  end

  def next_unfinished_term_for(legislature)
    legislature.legislative_periods.find do |lp|
      person_uuids = lp.csv.map { |p| p[:id] }.uniq
      remaining_counts.where(uuid: person_uuids).count > 0
    end
  end

  def record_vote(vote_data)
    vote = votes_dataset.first(person_uuid: vote_data[:person_uuid])
    if vote
      vote.update(choice: vote_data[:choice])
    else
      add_vote(vote_data)
    end
  end

  def votes_for_people(people, choice)
    votes_dataset.where(person_uuid: people.map { |p| p[:id] }, choice: choice)
  end

  def remaining_counts
    CountryUUID.where(gender: nil).exclude(
      votes_dataset.select(1).where(person_uuid: :country_uuids__uuid).exists
    ).group_and_count(:country_slug)
  end
end
