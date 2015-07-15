# Represents the result of a user choosing a gender for a politician.
class Response < Sequel::Model
  many_to_one :user

  def validate
    super
    validates_includes %w(male female other skip), :choice
  end

  def self.with_votes(vote_count)
    select(:politician_id, :country_code, :legislature_slug)
      .exclude(choice: 'skip')
      .group(:politician_id, :country_code, :legislature_slug)
      .having('count(choice) >= ?', vote_count)
  end

  # If people have answered both male and female then there are conflicts
  def no_conflicts?
    Response.where(politician_id: politician_id).group_and_count(:choice).count == 1
  end
end
