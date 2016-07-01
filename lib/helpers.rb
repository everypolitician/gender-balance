# Sinatra route helpers.
module Helpers
  def current_user
    @current_user ||= User[session[:user_id]]
  end

  def completed_onboarding?
    current_user && current_user.has_completed_onboarding? ||
      session[:completed_onboarding]
  end

  def motivational_quote
    settings.motivational_quotes.sample
  end

  def available_images(legislature)
    @available_images ||= begin
      index_txt_url = 'https://mysociety.github.io/politician-image-proxy/' \
        "#{legislature.country.slug}/#{legislature.slug}/index.txt"
      @available_images = open(index_txt_url).to_a.map(&:chomp)
    end
  rescue OpenURI::HTTPError => e
    warn "Couldn't retrieve list of available images: #{e.message}"
    []
  end

  def image_for?(legislature, person)
    available_images(legislature).include?(person[:id])
  end

  def image_for(legislature, person)
    [
      'https://mysociety.github.io/politician-image-proxy',
      legislature.country.slug,
      legislature.slug,
      URI.encode_www_form_component(person[:id]),
      '140x140.jpeg'
    ].join('/')
  end

  def previous_legislative_periods(legislative_period)
    legislature = legislative_period.legislature
    index = legislature.legislative_periods.index(legislative_period)
    legislature.legislative_periods[(index + 1)..-1]
  end

  def previous_legislative_period(legislative_period)
    previous_legislative_periods(legislative_period).first
  end

  def country_complete?
    return true if CountryUUID.where(country_slug: params[:country], gender: nil).empty?
    current_user && current_user.has_completed_country?(params[:country])
  end
end
