Sequel.migration do
  change do
    alter_table(:responses) do
      add_index [:user_id, :politician_id, :country_code, :legislature_slug], unique: true
    end
  end
end
