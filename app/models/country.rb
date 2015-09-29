class Country
  def self.all
    Sinatra::Application.cache_client.fetch('countries.json') do
      countries_json = 'https://github.com/everypolitician/' \
      'everypolitician-data/raw/master/countries.json'
      countries = Yajl.load(open(countries_json).read, symbolize_keys: true)
      countries.sort_by { |c| c[:name] }.map { |country| Country.new(country) }
    end
  end

  def self.find_by_slug(slug)
    country = all.find { |c| c[:slug] == slug }
    new(country) if country
  end

  def self.find_by_code(code)
    country = all.find { |c| c[:code] == code }
    new(country) if country
  end

  def initialize(country_data)
    @country_data = country_data
  end

  def legislature(legislature_slug)
    @country_data[:legislatures].find { |l| l[:slug] == legislature_slug }
  end

  def [](key)
    @country_data[key]
  end

  def gender_count
    counts = @country_data[:legislatures].map do |legislature|
      popolo_json = 'https://github.com/everypolitician/' \
      "everypolitician-data/raw/#{legislature[:sha]}/#{legislature[:popolo]}"
      popolo = Yajl.load(open(popolo_json).read, symbolize_keys: true)
      popolo[:persons].count { |p| p[:gender] }
    end
    counts.reduce(&:+)
  end
end
