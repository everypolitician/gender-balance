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
    people = legislative_period.unique_people
    already_done = responses_dataset
      .join(:legislative_periods, id: :legislative_period_id)
      .where(
        country_code: legislative_period.country_code,
        legislature_slug: legislative_period.legislature_slug
      )
      .map(:politician_id)
    people = people.reject { |person| already_done.include?(person[:id]) }
    people.uniq { |p| p[:id] }.shuffle
  end

  def legislative_periods_for(country, legislature)
    LegislativePeriod.where(country_code: country[:code], legislature_slug: legislature[:slug]).order(Sequel.desc(:start_date))
  end

  def last_response_for(country, legislature)
    responses_dataset.join(:legislative_periods, id: :legislative_period_id)
      .select(Sequel.qualify(:responses, :legislative_period_id))
      .where(country_code: country[:code], legislature_slug: legislature[:slug])
      .order(:start_date)
      .first
  end

  def legislative_period_for(country, legislature)
    legislative_periods = legislative_periods_for(country, legislature)
    last_response = last_response_for(country, legislature)
    if last_response
      last_legislative_period = LegislativePeriod[last_response.legislative_period_id]
    else
      last_legislative_period = legislative_periods.first
    end
    if incomplete?(last_legislative_period)
      last_legislative_period
    else
      legislative_periods.find { |lp| incomplete?(lp) }
    end
  end

  def incomplete?(legislative_period)
    people_for(legislative_period).any?
  end

  def has_completed_onboarding?
    completed_onboarding
  end
end
