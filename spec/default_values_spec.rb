require 'spec_helper'
require 'mash'

describe RedisModel::CustomSerializers do
  class Person < RedisModel::Base
    include RedisModel::DefaultValues

    default_values -> { Mash.new }, :mash_field
  end

  it 'sets a default value' do
    person = Person.new

    expect(person.mash_field).to eq Mash.new
  end
end
