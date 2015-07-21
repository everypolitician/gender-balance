Sequel.migration do
  change do
    create_table(:legislative_periods) do
      primary_key :id
      String :country_code, null: false
      String :legislature_slug, null: false
      String :legislative_period_id, null: false
      Date :start_date
      Integer :person_count
      DateTime :created_at
      DateTime :updated_at
    end
  end
end
