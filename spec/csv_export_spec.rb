require 'spec_helper'

describe CsvExport do
  subject { CsvExport.new('AU', 'Senate', id_map) }
  let(:user) { User.create(name: 'Bob Test', uid: '42', provider: 'twitter') }
  let(:legislative_period) { LegislativePeriod.create(country_code: 'AU', legislature_slug: 'Senate', legislative_period_id: 2, start_date: Date.new(2010)) }
  let(:id_map) do
    {
      'politician1' => 'pol1',
      'politician2' => 'pol2',
      'politician3' => 'pol3'
    }
  end

  before do
    {
      'politician1' => 'male',
      'politician2' => 'male',
      'politician3' => 'female',
    }.each do |politician_id, choice|
      Response.create(
        user_id: user.id,
        politician_id: politician_id,
        legislative_period_id: legislative_period.id,
        choice: choice
      )
    end
  end

  it 'returns the correct CSV' do
    expected = [
      {"uuid"=>"pol1", "female"=>nil, "male"=>"1", "other"=>nil, "skip"=>nil, "total"=>"1"},
      {"uuid"=>"pol2", "female"=>nil, "male"=>"1", "other"=>nil, "skip"=>nil, "total"=>"1"},
      {"uuid"=>"pol3", "female"=>"1", "male"=>nil, "other"=>nil, "skip"=>nil, "total"=>"1"}
    ]
    actual = CSV.parse(subject.to_csv, headers: true)
    assert_equal expected, actual.map(&:to_hash)
  end

  describe 'with duplicate responses' do
    before do
      Response.create(
        user_id: user.id,
        politician_id: "politician2",
        legislative_period_id: legislative_period.id,
        choice: 'skip'
      )
    end

    it "doesn't count votes twice" do
      expected = [
        {"uuid"=>"pol1", "female"=>nil, "male"=>"1", "other"=>nil, "skip"=>nil, "total"=>"1"},
        {"uuid"=>"pol2", "female"=>nil, "male"=>nil, "other"=>nil, "skip"=>"1", "total"=>"1"},
        {"uuid"=>"pol3", "female"=>"1", "male"=>nil, "other"=>nil, "skip"=>nil, "total"=>"1"}
      ]
      actual = CSV.parse(subject.to_csv, headers: true)
      assert_equal expected, actual.map(&:to_hash)
    end
  end
end
