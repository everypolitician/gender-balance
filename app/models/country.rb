class Country
  def self.all
    @countries ||= Sinatra::Application.cache_client.fetch('countries.json') do
      countries_json = 'https://github.com/everypolitician/' \
      'everypolitician-data/raw/master/countries.json'
      Yajl.load(open(countries_json).read, symbolize_keys: true)
    end
  end

  def self.find(slug)
    country = all.find { |c| c[:slug] == slug }
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
