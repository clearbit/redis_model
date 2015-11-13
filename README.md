# RedisModel

RedisModel is a basic ORM abstraction for Redis models.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'redis_model'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redis_model

## Usage

First inherit from `RedisModel::Base`

    class Person < RedisModel::Base
      self.primary_key = 'email'
    end

Then the API is similar to Sequel:

    # Create a person
    Person.create(email: 'alex@clearbit.com', name: 'Alex')

    # Find a person by primary key
    person = Person['alex@clearbit.com']

    # Access attributes
    person.name #= 'Alex'
    person.name = 'Harlow'

    # Do a full save (overwrites)
    person.save

    # Partial update
    person.update_all(title: 'Clearjoy')
