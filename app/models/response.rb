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

    def recent_country_codes
      countries
        .order(:country_code, Sequel.desc(Sequel.qualify(:responses, :created_at)))
        .limit(5)
        .map(:country_code)
    end
  end
end
