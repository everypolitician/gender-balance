# Caches a count of people in a country
class CountryCount < Sequel::Model
  def already_has_gender_data?
    person_count == gender_count
  end
end
