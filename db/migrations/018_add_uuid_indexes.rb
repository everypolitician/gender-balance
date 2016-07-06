Sequel.migration do
  change do
    alter_table(:country_uuids) do
      add_index :uuid
    end

    alter_table(:votes) do
      add_index :person_uuid
    end
  end
end
