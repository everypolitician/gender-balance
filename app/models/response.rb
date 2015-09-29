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
        .exclude(country_code: complete_countries.map(:country_code))
        .limit(limit)
        .map(:country_code)
    end

    def recent_countries(limit = 5)
      recent_country_codes(limit).map do |code|
        Country.find_by_code(code)
      end
    end

    def complete_countries
      join(:legislative_periods, id: :legislative_period_id)
        .group_and_count(:country_code)
        .having(
          'count(*) >= ?',
          CountryCount
            .select(:person_count)
            .where(country_code: Sequel.qualify(:legislative_periods, :country_code))
        )
    end

    def leaders(limit = 10)
      # Users get double points for responses created while a featured country
      # is active.
      double_points = {
        :responses__created_at => :featured_countries__start_date..:featured_countries__end_date
      }
      score = Sequel.case({double_points => 2}, 1)
      select(:users__id, :users__name)
        .select_append{sum(score).as(:count)}
        .join(:legislative_periods, id: :legislative_period_id)
        .join(:users, id: :responses__user_id)
        .left_outer_join(:featured_countries, country_code: :legislative_periods__country_code)
        .group(:users__id, :users__name)
        .order(Sequel.desc(:count))
        .limit(limit)
        .where{responses__created_at > 1.week.ago}
    end
  end
end
