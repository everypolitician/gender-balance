class UpdateCacheJob
  include Sidekiq::Worker

  def perform
    Everypolitician.countries.each do |country|
      puts "Caching #{country[:name]}"
      country.legislatures.each do |legislature|
        legislature.popolo.persons.each do |person|
          country_uuid = CountryUUID.find_or_create(
            country_slug: country.slug,
            legislature_slug: legislature.slug,
            uuid: person[:id]
          )
          country_uuid.update(gender: person[:gender])
        end
      end
    end
  end
end
