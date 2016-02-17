require 'spec_helper'

describe CountryProxy do
  let(:country) { Everypolitician.country(slug: 'Australia') }

  describe '#has_gender_data?' do
    it 'is false if there is no known gender data' do
      proxy = CountryProxy.new(country, { known: 0 }, nil, 3)
      assert !proxy.has_gender_data?, 'Expected subject.has_gender_data? to be false'
    end

    it 'is true if there is gender data' do
      proxy = CountryProxy.new(country, { known: 1 }, nil, 3)
      assert proxy.has_gender_data?, 'Expected subject.has_gender_data? to be true'
    end
  end
end
