Sequel.migration do
  change do
    alter_table :country_counts do
      set_column_default :gender_count, 0
    end
  end
end
