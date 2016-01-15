Sequel.migration do
  up do
    remove_duplicate_responses_sql = <<-SQL
DELETE FROM responses
WHERE (user_id, politician_id, created_at) NOT IN (
  SELECT user_id, politician_id, max(created_at)
  FROM responses
  GROUP BY user_id, politician_id
)
    SQL
    run(remove_duplicate_responses_sql)

    # Now add an index to prevent more duplicate responses.
    alter_table(:responses) do
      add_index [:user_id, :politician_id], unique: true
    end
  end

  down do
    alter_table(:responses) do
      drop_index [:user_id, :politician_id]
    end
  end
end
