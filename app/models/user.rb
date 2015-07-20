# Represents a user created from a social login.
class User < Sequel::Model
  one_to_many :responses

  def self.create_with_omniauth(auth)
    create do |user|
      user.provider = auth[:provider]
      user.uid = auth[:uid]
      user.name = auth[:info][:name] ||
        auth[:info][:nickname] ||
        auth[:info][:email]
    end
  end

  def people_for(legislative_period)
    people = legislative_period.csv
    already_done = responses_dataset
      .join(:legislative_periods, id: :legislative_period_id)
      .where(
        country_code: legislative_period.country_code,
        legislature_slug: legislative_period.legislature_slug
      )
      .map(:politician_id)
    people = people.reject { |person| already_done.include?(person[:id]) }
    people = people.reject { |person| person[:gender] }
    people.shuffle
  end

  def responses_for_country(country_code)
    responses_dataset.where(country_code: country_code)
  end

  def last_vote
    responses_dataset.join(:legislative_periods, id: :legislative_period_id).order(:start_date).first
  end

  def last_legislative_period
    LegislativePeriod.first(legislative_period_id: last_vote.legislative_period_id)
  end
end
