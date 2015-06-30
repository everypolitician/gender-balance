Sequel.migration do
  change do
    create_table(:responses) do
      primary_key :id
      foreign_key :user_id, :users, null: false, index: true
      String :politician_id, null: false
      String :country_code, null: false
      String :legislature_slug, null: false
      String :legislative_period_id, null: false
      String :choice, null: false
      DateTime :created_at
      DateTime :updated_at
    end
  end
end
