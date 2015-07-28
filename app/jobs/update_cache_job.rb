class UpdateCacheJob
  include Sidekiq::Worker

  def perform
    cache_country_person_counts
    cache_legislative_periods
  end

  def cache_country_person_counts
    Country.all.each do |country|
      puts "Caching person count for #{country[:name]}"
      country_count = CountryCount.find_or_create(country_code: country[:code])
      counts = country[:legislatures].map { |l| l[:person_count] }
      country_count.person_count = counts.reduce(:+)
      if country_count.respond_to?(:gender_count=)
        country_count.gender_count = country.gender_count
      end
      country_count.save
    end
  end

  def cache_legislative_periods
    countries_json = 'https://github.com/everypolitician/' \
      'everypolitician-data/raw/master/countries.json'
    countries = Yajl.load(open(countries_json).read, symbolize_keys: true)
    countries.each do |country|
      country[:legislatures].each do |legislature|
        legislature[:legislative_periods].each do |legislative_period|
          puts "Processing #{country[:name]} #{legislature[:name]} #{legislative_period[:name]}"
          lp = LegislativePeriod.find_or_create(
            country_code: country[:code],
            legislature_slug: legislature[:slug],
            legislative_period_id: legislative_period[:id]
          )
          start_date = legislative_period[:start_date]
          next if start_date.nil?
          start_date = "#{start_date}-01-01" if start_date.length == 4
          lp.start_date = Date.parse(start_date)
          lp.person_count = lp.unique_people.size
          lp.save
        end
      end
    end
  end
end