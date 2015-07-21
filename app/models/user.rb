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
    people = people.reject { |person| person[:gender] }
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
    return legislative_periods.first unless last_response
    last_legislative_period = LegislativePeriod[last_response.legislative_period_id]
    if incomplete?(last_legislative_period)
      last_legislative_period
    else
      legislative_periods_for(country, legislature)
        .where{start_date < last_legislative_period.start_date}.first
    end
  end

  def incomplete?(legislative_period)
    total = legislative_period.person_count
    completed = responses_dataset
      .join(:legislative_periods, id: :legislative_period_id)
      .where(
        country_code: legislative_period.country[:code],
        legislature_slug: legislative_period.legislature[:slug],
        politician_id: legislative_period.unique_people.map { |row| row[:id] }
      ).count
    already_have_gender = legislative_period.already_have_gender
    (completed + already_have_gender) != total
  end
end
