require 'spec_helper'

describe RedisModel do
  let(:test_class) { Class.new(RedisModel::Base) }
  let(:redis) { Redis.current }

  it 'has a version number' do
    expect(RedisModel::VERSION).not_to be nil
  end

  describe '.create' do
    it 'saves key/values and nested attributes' do
      test_class.create(id: '123', name: 'Alex', some_data: { a: 'ok' })

      result = test_class['123']

      expect(result.id).to eq '123'
      expect(result.name).to eq 'Alex'
      expect(result.some_data).to eq({ 'a' => 'ok' })
    end
  end

  describe '.find' do
    it 'returns record' do
      test_class.create(id: '123', name: 'Alex')

      result = test_class['123']

      expect(result.id).to eq('123')
      expect(result.name).to eq('Alex')
    end

    it 'returns nil when record not found' do
      result = test_class['unknown_id']

      expect(result).to eq nil
    end
  end

  describe '#save' do
    it 'raises if the primary key is nil' do
      person = test_class.new(name: 'Alex')

      expect { person.save }.to raise_exception(RedisModel::PrimaryKeyError)
    end

    it 'saves a record to Redis' do
      person = test_class.new(id: '123')
      person.name = 'Alex'

      person.save

      expect(redis.hget(person.key, 'name')).to eq("\"Alex\"")
    end
  end

  describe '#update_all' do
    it 'only saves changed attributes' do
      person = test_class.create(id: '123', name: 'Alex')
      redis.hset(person.key, 'name', "\"Bob\"")

      person.update_all(thingy: 'blah')

      expect(person.name).to eq('Bob')
      expect(test_class['123'].name).to eq('Bob')
    end
  end

  describe '#method_missing' do
    it 'handles predicate methods for known values' do
      person = test_class.new(pet_owner: true)

      expect(person.pet_owner?).to eq true
    end

    it 'handles assignment to known values' do
      person = test_class.new

      person.pet_owner = true

      expect(person.pet_owner).to eq true
    end

    it 'calls super for unknown values' do
      person = test_class.new

      expect(-> { person.pet_owner }).to raise_exception(NoMethodError)
    end

    it 'sends methods when using question mark' do
      test_class = Class.new(RedisModel::Base) do
        def unknown?
          !(name? || id?)
        end
      end

      person = test_class.new
      expect(person.unknown?).to eq true

      person.name = 'Harlow'
      expect(person.unknown?).to eq false
    end
  end

  describe '#respond_to?' do
    it 'returns true for known values' do
      person = test_class.new(pet_owner: true)

      expect(person.respond_to?(:pet_owner)).to eq true
      expect(person.respond_to?(:pet_owner?)).to eq true
      expect(person.respond_to?(:pet_owner=)).to eq true
    end

    it 'returns false for unknown values' do
      person = test_class.new

      expect(person.respond_to?(:pet_owner)).to eq false
      expect(person.respond_to?(:pet_owner?)).to eq false
      expect(person.respond_to?(:pet_owner=)).to eq false
    end
  end
end
