class CsvExport
  attr_reader :country_code
  attr_reader :legislature_slug
  attr_reader :id_map

  def initialize(country_code, legislature_slug, id_map)
    @country_code = country_code
    @legislature_slug = legislature_slug
    @id_map = id_map
  end

  def to_csv
    counts = {}
    # This is purposely overwriting earlier votes by a user with later ones so
    # that we only count one vote for a politician per user.
    votes.each do |row|
      politician_id = id_map[row[:politician_id]]
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
    @votes ||= Response
      .select(:politician_id, :user_id, :choice)
      .join(:legislative_periods, legislative_periods__id: :responses__legislative_period_id)
      .where(country_code: country_code, legislature_slug: legislature_slug)
      .order(:responses__created_at)
  end
end
