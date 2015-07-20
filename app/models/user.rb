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
    responses_dataset.for_country_code(country_code)
  end

  def last_response
    responses.first
  end

  def responses
    responses_dataset.join(:legislative_periods, id: :legislative_period_id).order(:start_date)
  end

  def last_legislative_period
    LegislativePeriod.first(legislative_period_id: last_response.legislative_period_id)
  end

  def legislative_period_for(country, legislature)
    if responses_for_country(country[:code]).empty?
      LegislativePeriod.for_country_code(country[:code]).first
    end
  end
end
