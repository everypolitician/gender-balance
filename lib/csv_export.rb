class CsvExport
  attr_reader :country
  attr_reader :legislature

  def initialize(country, legislature)
    @country = country
    @legislature = legislature
  end

  def to_csv
    counts = {}
    # This is purposely overwriting earlier votes by a user with later ones so
    # that we only count one vote for a politician per user.
    votes.each do |row|
      politician_id = row[:person_uuid]
      counts[politician_id] ||= {}
      counts[politician_id][row[:user_id]] = row[:choice]
    end
    headers = ['uuid', 'female', 'male', 'other', 'skip', 'total']
    rows = counts.map do |politician_id, per_person_votes|
      v = Hash[per_person_votes.values.group_by { |t| t }.map { |t, c| [t, c.size] }]
      [politician_id, v['female'], v['male'], v['other'], v['skip'], v.values.compact.reduce(&:+)]
    end
    CSV.generate do |csv|
      csv << headers
      rows.each { |row| csv << row }
    end
  end

  def votes
    @votes ||= Vote
      .select(:person_uuid, :user_id, :choice)
      .join(:country_uuids, uuid: :person_uuid)
      .where(country_slug: country.slug)
      .order(:votes__created_at)
  end
end
