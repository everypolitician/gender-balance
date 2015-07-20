# Sinatra route helpers.
module Helpers
  def current_user
    @current_user ||= User[session[:user_id]]
  end

  def csv_for(ref, path, last_modified)
    cache [ref, path, last_modified].join(':'), expiry: 1.month do
      csv_url = 'https://cdn.rawgit.com/everypolitician/everypolitician-data/' \
        "#{ref}/#{path}"
      CSV.parse(open(csv_url).read, headers: true, header_converters: :symbol)
    end
  end

  def countries
    @countries ||= cache 'countries.json' do
      countries_json = 'https://github.com/everypolitician/' \
      'everypolitician-data/raw/master/countries.json'
      Yajl.load(open(countries_json).read, symbolize_keys: true)
    end
  end

  def country_counts
    @country_counts ||= CountryCount.to_hash(:country_code, :person_count)
  end

  def started_countries
    @started_countries ||= current_user.responses_dataset.country_codes
  end

  def percent_complete(country)
    return 0 unless started_countries.include?(country[:code])
    @percent_complete_countries ||= {}
    @percent_complete_countries[country[:code]] ||=
      begin
        total_people = country_counts[country[:code]]
        complete_people = current_user.responses_dataset
          .join(:legislative_periods, id: :legislative_period_id)
          .where(country_code: country[:code])
          .count
        (complete_people.to_f / total_people.to_f) * 100
      end
  end

  def percent_complete_term(country, legislature, legislative_period)
    csv = csv_for(
      legislature[:sha],
      legislative_period[:csv],
      legislature[:lastmod]
    )
    total_people = csv.size
    response_count = current_user.responses_dataset.join(:legislative_periods, id: :legislative_period_id).where(
      politician_id: csv.map { |row| row[:id] },
      country_code: country[:code],
      legislature_slug: legislature[:slug]
    ).count
    complete_people = response_count
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
end
