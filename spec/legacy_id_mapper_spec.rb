require 'spec_helper'

describe LegacyIdMapper do
  let(:popolo) do
    {
      persons: [
        {
          id: 'af3e71ab-01f9-4190-a988-79944eeed8e7',
          identifiers: [
            { scheme: 'everypolitician_legacy', identifier: 'bob' }
          ]
        },
        {
          id: 'another-uuid',
          identifiers: [
            { scheme: 'everypolitician_legacy', identifier: 'john-smith' }
          ]
        },
        {
          id: 'new-uuid'
        },
        {
          id: 'person/alice'
        }
      ]
    }
  end

  subject { LegacyIdMapper.new(popolo) }

  it 'maps the new id to the everypolitician_legacy identifier' do
    assert_equal 'bob', subject['af3e71ab-01f9-4190-a988-79944eeed8e7']
    assert_equal 'john-smith', subject['another-uuid']
  end

  it "returns the given id if there's no legacy id" do
    assert_equal 'new-uuid', subject['new-uuid']
  end

  it 'returns the id unchanged if not found in the source data' do
    assert_equal 'alice', subject['alice']
    assert_equal 'missing', subject['missing']
  end
end
