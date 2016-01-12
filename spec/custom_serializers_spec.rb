require 'spec_helper'
require 'mash'

describe RedisModel::CustomSerializers do
  let(:test_class) do
    Class.new(RedisModel::Base) do
      include RedisModel::CustomSerializers

      serialize_attributes :json, :json_field
      serialize_attributes :mash, :mash_field
    end
  end

  describe 'json serializer' do
    it 'stores null values' do
      test_class.create(id: 123, json_field: nil)

      person = test_class['123']

      expect(person.json_field).to eq nil
    end

    it 'symbolizes keys' do
      test_class.create(id: 123, json_field: { 'x' => 1 })

      person = test_class['123']

      expect(person.json_field).to eq({ x: 1 })
    end
  end

  describe 'mash serializer' do
    it 'returns an empty Mash for null values' do
      test_class.create(id: 123, mash_field: nil)

      person = test_class['123']

      expect(person.mash_field).to eq Mash.new
    end
  end
end
