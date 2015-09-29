class FeaturedCountry < Sequel::Model
  dataset_module do
    def current
      where{start_date <= DateTime.now}
        .where{end_date >= DateTime.now}
        .first
    end
  end
end
