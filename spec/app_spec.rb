require 'spec_helper'

describe 'App' do
  it 'has a homepage' do
    get '/'
    assert last_response.ok?
  end
end
