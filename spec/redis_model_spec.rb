require 'spec_helper'

describe RedisModel do
  class Person < RedisModel::Base
  end

  let(:redis) { Redis.current }

  it 'has a version number' do
    expect(RedisModel::VERSION).not_to be nil
  end

  it 'saves a record to Redis' do
    person = Person.new(id: '123')
    person.name = 'Alex'
    person.save

    expect(redis.hget(person.key, 'name')).to eq("{\"v\":\"Alex\"}")
  end

  it 'loads a record from Redis' do
    person = Person.new(id: '123')
    person.name = 'Alex'
    person.save

    expect(Person['123'].name).to eq('Alex')
  end

  it 'returns nil when person not found' do
    expect(Person[id: 'notfound']).to eq(nil)
  end

  it 'only saves changes' do
    person = Person.new(id: '123')
    person.name = 'Alex'
    person.save

    redis.hset(person.key, 'name', "{\"v\":\"Bob\"}")

    person.update_all(thingy: 'blah')

    expect(person.name).to eq('Bob')
    expect(Person['123'].name).to eq('Bob')
  end
end
