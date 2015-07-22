Sequel.migration do
  change do
    alter_table :country_counts do
      add_column :gender_count, Integer
    end
  end
end
