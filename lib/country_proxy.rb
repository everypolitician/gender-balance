class CountryProxy
  extend Forwardable

  attr_reader :country
  attr_reader :totals

  # Delegate 'name' and 'slug' method calls to the 'country' object.
  def_delegators :country, :name, :slug, :code

  def initialize(country, totals)
    @country = country
    @totals = totals
  end
end
