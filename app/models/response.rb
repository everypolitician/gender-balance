# Represents the result of a user choosing a gender for a politician.
class Response < Sequel::Model
  many_to_one :user
  many_to_one :legislative_period

  def validate
    super
    validates_includes %w(male female other skip), :choice
  end

  dataset_module do
    def for_country_code(country_code)
      join(:legislative_periods, id: :legislative_period_id)
        .where(country_code: country_code)
    end

    def countries
      join(:legislative_periods, id: :legislative_period_id)
        .distinct(:country_code)
        .select(:country_code, Sequel.qualify(:responses, :created_at))
        .order(:country_code, Sequel.desc(:created_at))
    end

    def country_codes
      countries.map(:country_code)
    end

    def recent_country_codes(limit = 5)
      Response.from(countries)
        .order(Sequel.desc(:created_at))
        .limit(limit)
        .map(:country_code)
    end

    def recent_countries(limit = 5)
      recent_country_codes(limit).map do |code|
        Country.find_by_code(code)
      end
    end
  end
end
