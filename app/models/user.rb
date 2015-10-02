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
    people.shuffle
  end

  def legislative_periods_for(country, legislature)
    LegislativePeriod.enabled.where(
      country_code: country[:code],
      legislature_slug: legislature[:slug]
    ).order(Sequel.desc(:start_date))
  end

  def legislative_period_for(country, legislature)
    legislative_periods_for(country, legislature).find { |lp| incomplete?(lp) }
  end

  def incomplete?(legislative_period)
    !legislative_period.missing? && people_for(legislative_period).any?
  end

  def has_completed_onboarding?
    completed_onboarding
  end

  def played_when_featured(country)
    featured_country = FeaturedCountry.first(country_code: country[:code])
    responses_dataset
      .join(:legislative_periods, id: :legislative_period_id)
      .where(country_code: country[:code])
      .where{responses__created_at > featured_country.start_date}
      .where{responses__created_at < featured_country.end_date}
      .any?
  end
end
