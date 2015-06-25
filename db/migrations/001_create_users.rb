Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id
      String :name, null: false
      String :uid, null: false
      String :provider, null: false
      DateTime :created_at
      DateTime :updated_at
    end
  end
end
