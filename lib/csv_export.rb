class CsvExport
  attr_reader :country
  attr_reader :legislature

  def initialize(country, legislature)
    @country = country
    @legislature = legislature
  end

  def to_csv
    CSV.generate do |csv|
      csv << vote_totals.first.keys
      vote_totals.each { |vote| csv << vote.to_hash.values }
    end
  end

  def vote_totals
    @vote_totals ||= Vote
      .select(:person_uuid___uuid)
      .select_append(votes_for(:female))
      .select_append(votes_for(:male))
      .select_append(votes_for(:other))
      .select_append(votes_for(:skip))
      .select_append(Sequel.function(:count).*.as(:total))
      .join(:country_uuids, uuid: :person_uuid)
      .where(country_slug: country.slug)
      .group(:person_uuid)
      .order(:person_uuid)
  end

  def votes_for(choice)
    Vote.from(:votes___iv)
      .select(Sequel.function(:count).*)
      .where(choice: choice.to_s, iv__person_uuid: :votes__person_uuid).as(choice.to_sym)
  end
end
