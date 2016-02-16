class CountryProxy
  extend Forwardable

  attr_reader :country
  attr_reader :totals
  attr_reader :user_vote_count

  # Delegate 'name' and 'slug' method calls to the 'country' object.
  def_delegators :country, :name, :slug, :code

  def initialize(country, totals, user_vote_count, remaining_people)
    @country = country
    @totals = totals
    @user_vote_count = user_vote_count
    @remaining_people = remaining_people
  end

  def remaining_people
    @remaining_people || 0
  end

  def has_gender_data?
    totals[:known] != 0
  end

  def gender_percentage(gender)
    (totals[gender.to_sym].to_f / totals[:total]) * 100
  end

  def complete?
    remaining_people == 0
  end

  def played_by_user?
    !user_vote_count.nil?
  end

  def total_male
    totals[:male]
  end

  def total_female
    totals[:female]
  end
end
