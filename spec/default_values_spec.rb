require 'spec_helper'
require 'mash'

describe RedisModel::CustomSerializers do
  let(:test_class) do
    Class.new(RedisModel::Base) do
      include RedisModel::DefaultValues

      default_values -> { Mash.new }, :mash_field
    end
  end

  it 'sets a default value' do
    person = test_class.new

    expect(person.mash_field).to eq Mash.new
  end

  it 'uses a default value if the field exists but is set to nil' do
    person = test_class.new(mash_field: nil)

    expect(person.mash_field).to eq Mash.new
  end
end
