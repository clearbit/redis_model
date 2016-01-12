require 'spec_helper'

describe RedisModel::AutoId do
  let(:test_class) do
    Class.new(RedisModel::Base) do
      include RedisModel::AutoId
    end
  end

  describe '#id' do
    it 'generates an id if required' do
      person = test_class.new(name: 'Alex')

      expect(person.id).to_not eq nil
    end
  end

  describe '#save' do
    it 'generates an id if required' do
      person = test_class.new(name: 'Alex')

      expect { person.save }.not_to raise_error

      expect(person.id).to_not be_nil
    end
  end
end
