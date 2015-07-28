# Sinatra route helpers.
module Helpers
  def current_user
    @current_user ||= User[session[:user_id]]
  end

  def country_counts
    @country_counts ||= CountryCount.to_hash(:country_code)
  end

  def started_countries
    @started_countries ||= current_user.responses_dataset.country_codes
  end

  def completed_onboarding?
    current_user && current_user.has_completed_onboarding? ||
      session[:completed_onboarding]
  end

  def percent_complete(country)
    @percent_complete_countries ||= {}
    @percent_complete_countries[country[:code]] ||=
      begin
        country_count = country_counts[country[:code]]
        return 0 if country_count.nil?
        total_people = country_count.person_count
        complete_people = current_user.responses_dataset
          .join(:legislative_periods, id: :legislative_period_id)
          .where(country_code: country[:code])
          .count
        complete_people = complete_people + country_count.gender_count
        (complete_people.to_f / total_people.to_f) * 100
      end
  end

  def percent_complete_term(legislative_period)
    total_people = legislative_period.unique_people.size
    response_count = current_user.responses_dataset
      .join(:legislative_periods, id: :legislative_period_id)
      .where(
        politician_id: legislative_period.unique_people.map { |row| row[:id] },
        legislature_slug: legislative_period.legislature[:slug]
      ).count
    gender_count = legislative_period.unique_people.count { |p| p[:gender] }
    complete_people = (response_count + gender_count)
    (complete_people.to_f / total_people.to_f) * 100
  end

  def progress_word(percent)
    case
    when percent > 70
      'healthy'
    when percent > 10
      'unhealthy'
    else
      'dangerous'
    end
  end

  def motivational_quote
    settings.motivational_quotes.sample
  end
end
