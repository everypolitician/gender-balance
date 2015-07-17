Sequel.migration do
  up do
    alter_table(:responses) do
      rename_column :legislative_period_id, :lp_id
      add_foreign_key :legislative_period_id, :legislative_periods
    end
    from(:responses).each do |response|
      lp = from(:legislative_periods).where(
        country_code: response[:country_code],
        legislature_slug: response[:legislature_slug],
        legislative_period_id: response[:lp_id]
      ).first
      from(:responses).where(id: response[:id]).update(legislative_period_id: lp[:id])
    end
    alter_table(:responses) do
      drop_column :country_code
      drop_column :legislature_slug
      drop_column :lp_id
    end
  end

  down do
    alter_table(:responses) do
      drop_foreign_key :legislative_period_id
      rename_column :lp_id, :legislative_period_id
    end
  end
end
