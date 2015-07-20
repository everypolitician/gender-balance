class LegislativePeriod < Sequel::Model
  one_to_many :responses

  dataset_module do
    def for_country_code(country_code)
      where(country_code: country_code).order(Sequel.desc(:start_date))
    end
  end

  def name
    legislative_period[:name]
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

  def cache_key
    @cache_key ||= [
      legislature[:sha],
      legislative_period[:csv],
      legislature[:lastmod]
    ].join(':')
  end

  def csv
    Sinatra::Application.cache_client.fetch(cache_key, 1.month) do
      csv_url = 'https://cdn.rawgit.com/everypolitician/everypolitician-data/' \
        "#{legislature[:sha]}/#{legislative_period[:csv]}"
      CSV.parse(open(csv_url).read, headers: true, header_converters: :symbol)
    end
  end

  def already_have_gender
    csv.count { |person| person[:gender] }
  end
end
