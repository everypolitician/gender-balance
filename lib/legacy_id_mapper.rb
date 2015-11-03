# Maps new EveryPolitician UUIDs to legacy ids
class LegacyIdMapper
  def initialize(popolo)
    id_mapping = popolo[:persons].map do |person|
      next unless person[:identifiers]
      legacy_id = person[:identifiers].find do |i|
        i[:scheme] == 'everypolitician_legacy'
      end
      next unless legacy_id
      [person[:id], legacy_id[:identifier]]
    end
    @map = Hash[id_mapping.compact]
  end

  def [](id)
    @map.fetch(id, id)
  end
end
