# Represents the result of a user choosing a gender for a politician.
class Response < Sequel::Model
  many_to_one :user

  def validate
    super
    validates_includes %w(male female other skip), :choice
  end
end
