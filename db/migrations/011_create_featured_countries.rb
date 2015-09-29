Sequel.migration do
  change do
    create_table(:featured_countries) do
      primary_key :id
      String :country_code, null: false
      DateTime :start_date, null: false
      DateTime :end_date, null: false
    end
  end
end
