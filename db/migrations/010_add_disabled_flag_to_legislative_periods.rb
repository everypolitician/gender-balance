Sequel.migration do
  change do
    alter_table(:legislative_periods) do
      add_column :disabled, TrueClass, default: false
    end
  end
end
