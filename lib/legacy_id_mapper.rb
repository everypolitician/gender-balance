# Maps new EveryPolitician UUIDs to legacy ids
class LegacyIdMapper
  class Map
    def initialize(map)
      @map = Hash[map]
    end

    def [](id)
      @map.fetch(id, id)
    end
  end

  attr_reader :reverse_map

  def initialize(popolo)
    id_mapping = popolo[:persons].map do |person|
      next unless person[:identifiers]
      legacy_id = person[:identifiers].find do |i|
        i[:scheme] == 'everypolitician_legacy'
      end
      next unless legacy_id
      [person[:id], legacy_id[:identifier]]
    end
    id_mapping.compact!
    @map = Map.new(id_mapping)
    @reverse_map = Map.new(id_mapping.map { |idm| idm.reverse })
  end

  def [](id)
    @map[id]
  end
end
