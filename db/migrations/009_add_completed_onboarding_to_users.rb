Sequel.migration do
  up do
    alter_table :users do
      add_column :completed_onboarding, FalseClass, default: false, null: false
    end
    from(:users).update(completed_onboarding: true)
  end

  down do
    alter_table :users do
      drop_column :completed_onboarding
    end
  end
end
