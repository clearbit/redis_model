require 'spec_helper'

describe RedisModel do
  class Person < RedisModel::Base
  end

  let(:redis) { Redis.current }

  it 'has a version number' do
    expect(RedisModel::VERSION).not_to be nil
  end

  describe '.create' do
    it 'saves key/values and nested attributes' do
      Person.create(id: '123', name: 'Alex', some_data: { a: 'ok' })

      result = Person['123']

      expect(result.id).to eq '123'
      expect(result.name).to eq 'Alex'
      expect(result.some_data).to eq({ 'a' => 'ok' })
    end
  end

  describe '.find' do
    it 'returns record' do
      Person.create(id: '123', name: 'Alex')

      result = Person['123']

      expect(result.id).to eq('123')
      expect(result.name).to eq('Alex')
    end

    it 'returns nil when record not found' do
      result = Person['unknown_id']

      expect(result).to eq nil
    end
  end

  describe '#save' do
    it 'saves a record to Redis' do
      person = Person.new(id: '123')
      person.name = 'Alex'

      person.save

      expect(redis.hget(person.key, 'name')).to eq("\"Alex\"")
    end
  end

  describe '#update_all' do
    it 'only saves changed attributes' do
      person = Person.create(id: '123', name: 'Alex')
      redis.hset(person.key, 'name', "\"Bob\"")

      person.update_all(thingy: 'blah')

      expect(person.name).to eq('Bob')
      expect(Person['123'].name).to eq('Bob')
    end
  end

  describe '#method_missing' do
    it 'handles predicate methods for known values' do
      person = Person.new(pet_owner: true)

      expect(person.pet_owner?).to eq true
    end

    it 'handles assignment to known values' do
      person = Person.new

      person.pet_owner = true

      expect(person.pet_owner).to eq true
    end

    it 'calls super for unknown values' do
      person = Person.new

      expect(-> { person.pet_owner }).to raise_exception(NoMethodError)
    end
  end

  describe '#respond_to?' do
    it 'returns true for known values' do
      person = Person.new(pet_owner: true)

      expect(person.respond_to?(:pet_owner)).to eq true
      expect(person.respond_to?(:pet_owner?)).to eq true
      expect(person.respond_to?(:pet_owner=)).to eq true
    end

    it 'returns false for unknown values' do
      person = Person.new

      expect(person.respond_to?(:pet_owner)).to eq false
      expect(person.respond_to?(:pet_owner?)).to eq false
      expect(person.respond_to?(:pet_owner=)).to eq false
    end
  end
end
