require 'spec_helper'
require 'mash'

describe RedisModel::CustomSerializers do
  class Person < RedisModel::Base
    include RedisModel::CustomSerializers

    serialize_attributes :json, :json_field
    serialize_attributes :mash, :mash_field
  end

  let(:redis) { Redis.current }

  describe 'json serializer' do
    it 'stores null values' do
      Person.create(id: 123, json_field: nil)

      person = Person['123']

      expect(person.json_field).to eq nil
    end

    it 'symbolizes keys' do
      Person.create(id: 123, json_field: { 'x' => 1 })

      person = Person['123']

      expect(person.json_field).to eq({ x: 1 })
    end
  end

  describe 'mash serializer' do
    it 'returns an empty Mash for null values' do
      Person.create(id: 123, mash_field: nil)

      person = Person['123']

      expect(person.mash_field).to eq(Mash.new)
    end
  end
end
