class Country
  def self.all
    @countries ||= Sinatra::Application.cache_client.fetch('countries.json') do
      countries_json = 'https://github.com/everypolitician/' \
      'everypolitician-data/raw/master/countries.json'
      countries = Yajl.load(open(countries_json).read, symbolize_keys: true)
      countries.map { |country| Country.new(country) }
    end
  end

  def self.find_by_slug(slug)
    country = all.find { |c| c[:slug] == slug }
    new(country)
  end

  def self.find_by_code(code)
    country = all.find { |c| c[:code] == code }
    new(country)
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
end
