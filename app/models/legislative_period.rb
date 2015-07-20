class LegislativePeriod < Sequel::Model
  one_to_many :responses

  dataset_module do
    def for_country_code(country_code)
      where(country_code: country_code).order(Sequel.desc(:start_date))
    end
  end

  def country
    @country ||= Country.find_by_code(country_code)
  end

  def legislature
    @legislature ||= country[:legislatures].find { |l| l[:slug] == legislature_slug }
  end

  def legislative_period
    @legislative_period ||= legislature[:legislative_periods].find do |lp|
      lp[:id] == legislative_period_id
    end
  end

  def people
    people = csv_for(legislature[:sha], legislative_period[:csv], legislature[:lastmod])
    already_done = current_user.responses_dataset.join(:legislative_periods, id: :legislative_period_id).select(:politician_id).where(
      country_code: @country[:code],
      legislature_slug: @legislature[:slug]
    ).map(&:politician_id)
    people = people.reject { |person| already_done.include?(person[:id]) }
    people = people.reject { |person| person[:gender] }
    people.shuffle
  end

  def cache_key
    @cache_key ||= [
      legislature[:sha],
      legislative_period[:csv],
      legislature[:lastmod]
    ].join(':')
  end

  def csv
    Sinatra::Application.cache_client.fetch(cache_key, 1.month) do
      p legislature
      csv_url = 'https://cdn.rawgit.com/everypolitician/everypolitician-data/' \
        "#{legislature[:sha]}/#{legislative_period[:csv]}"
      puts csv_url
      CSV.parse(open(csv_url).read, headers: true, header_converters: :symbol)
    end
  end
end
