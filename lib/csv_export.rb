class CsvExport
  attr_reader :country_slug
  attr_reader :legislature_slug

  def initialize(country_slug, legislature_slug)
    @country_slug = country_slug
    @legislature_slug = legislature_slug
  end

  def to_csv
    CSV.generate do |csv|
      csv << vote_totals.columns
      vote_totals.each { |vote| csv << vote.to_hash.values }
    end
  end

  def vote_totals
    @vote_totals ||= Vote
      .select(
        :person_uuid___uuid,
        votes_for(:female),
        votes_for(:male),
        votes_for(:other),
        votes_for(:skip),
        Sequel.function(:count).*.as(:total)
      )
      .join(:country_uuids, uuid: :person_uuid)
      .where(country_slug: country_slug, legislature_slug: legislature_slug)
      .group(:person_uuid)
      .order(:person_uuid)
  end

  def votes_for(choice)
    Sequel.function(:count, Sequel.case({ choice.to_s => 1 }, nil, :choice)).as(choice)
  end
end
