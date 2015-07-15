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

  def percent_complete(country)
    return 0 if current_user.responses_for_country(country[:code]).empty?
    complete_people = 0
    total_people = 0
    country[:legislatures].each do |legislature|
      legislature[:legislative_periods].each do |legislative_period|
        complete, total = term_counts(country, legislature, legislative_period)
        complete_people += complete
        total_people += total
      end
    end
    (complete_people.to_f / total_people.to_f) * 100
  end

  def term_counts(country, legislature, legislative_period)
    csv = csv_for(
      legislature[:sha],
      legislative_period[:csv],
      legislature[:lastmod]
    )
    total_people = csv.size
    response_count = current_user.responses_dataset.where(
      politician_id: csv.map { |row| row[:id] },
      country_code: country[:code],
      legislature_slug: legislature[:slug]
    ).count
    complete_people = response_count
    [complete_people.to_f, total_people.to_f]
  end

  def percent_complete_term(country, legislature, legislative_period)
    complete, total = term_counts(country, legislature, legislative_period)
    (complete / total) * 100
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
