# Sinatra route helpers.
module Helpers
  def current_user
    @current_user ||= User[session[:user_id]]
  end

  def csv_for(ref, path, last_modified)
    cache [ref, path, last_modified].join(''), expiry: 1.day do
      csv_url = 'https://cdn.rawgit.com/everypolitician/everypolitician-data/' \
        "#{ref}/#{path}"
      CSV.parse(open(csv_url).read, headers: true, header_converters: :symbol)
    end
  end

  def countries
    cache 'countries.json' do
      countries_json = 'https://github.com/everypolitician/' \
      'everypolitician-data/raw/master/countries.json'
      Yajl.load(open(countries_json).read, symbolize_keys: true)
    end
  end
end
