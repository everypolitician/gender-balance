Sequel.migration do
  change do
    alter_table(:country_uuids) do
      add_column :gender, String
    end
  end
end
