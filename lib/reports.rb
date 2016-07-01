module Reports
  # Require including class to define a `stats` method which returns a hash with
  # :female, :male and :total keys.
  module GenderStats
    def female
      @female ||= stats[:female].to_f
    end

    def male
      @male ||= stats[:male].to_f
    end

    def total
      @total ||= stats[:total].to_f
    end

    def female_percentage
      @female_percentage ||= female / total * 100
    end

    def male_percentage
      @male_percentage ||= male / total * 100
    end
  end

  class LegislatureReport
    extend Forwardable
    include GenderStats

    # Delegate 'name' and 'slug' method calls to the 'legislature' object.
    def_delegators :legislature, :name, :slug

    attr_reader :legislature
    attr_reader :raw_stats

    def initialize(legislature, raw_stats)
      @legislature = legislature
      @raw_stats = raw_stats
    end

    def stats
      @stats ||= raw_stats[:totals][:overall]
    end

    def groups
      @groups ||= raw_stats[:totals][:parties].map { |slug, group_stats| GroupReport.new(slug, group_stats, raw_stats, legislative_periods) }
    end

    def legislative_periods
      @legislative_periods ||= legislature.legislative_periods.map { |lp| LegislativePeriodReport.new(lp, raw_stats) }
    end
  end

  class GroupReport
    include GenderStats

    attr_reader :slug
    attr_reader :stats
    attr_reader :raw_stats

    def initialize(slug, stats, raw_stats, legislative_periods)
      @slug = slug
      @stats = stats
      @raw_stats = raw_stats
      @legislative_periods = legislative_periods
    end

    def name
      stats[:name]
    end

    def id_slug
      @id_slug ||= slug.to_s.sub('/', '-')
    end

    def legislative_periods
      @legislative_periods.map do |term|
        term_stats = raw_stats[:terms]["term/#{term.slug}".to_sym]
        group_stats = term_stats[:parties][slug]
        GroupLegilativePeriodReport.new(term, group_stats) if group_stats
      end.compact
    end
  end

  class GroupLegilativePeriodReport
    include GenderStats

    attr_reader :term
    attr_reader :stats

    def initialize(term, stats)
      @term = term
      @stats = stats
    end

    def name
      term.name
    end
  end

  class LegislativePeriodReport
    extend Forwardable
    include GenderStats

    # Delegate 'name' and 'slug' method calls to the 'legislative_period' object.
    def_delegators :legislative_period, :name, :slug

    attr_reader :legislative_period
    attr_reader :raw_stats

    def initialize(legislative_period, raw_stats)
      @legislative_period = legislative_period
      @raw_stats = raw_stats
    end

    def legislative_period_stats
      @legislative_period_stats ||= raw_stats[:terms]["term/#{legislative_period.slug}".to_sym]
    end

    def stats
      @stats ||= legislative_period_stats[:overall]
    end

    def groups
      @groups = legislative_period_stats[:parties].map { |_, group_stats| LegislativePeriodGroupReport.new(group_stats) }
    end
  end

  class LegislativePeriodGroupReport
    include GenderStats

    attr_reader :stats

    def initialize(stats)
      @stats = stats
    end

    def name
      stats[:name]
    end
  end
end
