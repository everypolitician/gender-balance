Sequel.migration do
  change do
    create_table(:country_counts) do
      primary_key :id
      String :country_code, null: false, unique: true
      Integer :person_count
      DateTime :created_at
      DateTime :updated_at
    end
  end
end
