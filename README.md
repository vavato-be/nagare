# nagare - A publish/subscribe library backed by Redis Streams

Nagare (flow in japanese) makes it easy to work with **Redis Streams** events 
in Ruby and Rails. This enables publish/subscribe patterns in your applications
and can be handy to enable event-driven architectures. It may also assist in 
the decomposition and decoupling of Rails monoliths into microservices.


## Guarantees & Behaviour
Nagare guarantees through the use of Redis Streams Groups exactly-once delivery
of messages to listeners. Nagare is infinitely horizontally scalable, adding new
servers running Nagare will add more consumers to the listener group in redis.

By hooking into ActiveRecord transactions, Nagare automatically ACK's messages
only on successful transactions, and automatically retries failed ones according
to configuration.

Nagare ensures that if a listener is removed or dies, messages are redistributed
to other listeners as soon as they become available, based on a timeout. For more
information on how this works see 
[Recovering from permanent failures](https://redis.io/topics/streams-intro#recovering-from-permanent-failures)

### Configuration

Add this line to your application's Gemfile:

```ruby
gem 'nagare-redis'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install nagare

To use with rails, add nagare to the initializers:
#### config/initializers/nagare.rb
```ruby
Nagare.configure do |config|
  # After x seconds a consumer is considered dead and its messages
  # are assigned to a different consumer in the group. Configuring
  # it too low might cause double processing of messages as a consumer
  # "steals" the load of another while the first one is still processing
  # it and hasn't had the chance to ACK, configuring it too high will 
  # introduce latency in your processing.
  # Default: 300 (5 minutes)
  config.dead_consumer_timeout = 600

  # This is the consumer group name that will be used or created in
  # Redis. Use a different group for every microservice / application
  # Default: Rails.env
  config.group_name = :monolith

  # URL to connect to redis. Defaults to redis://localhost:6379 uses 
  # ENV['REDIS_URL'] if present.
  config.redis_url = 'redis://10.1.1.1:6379'

  # Nagare uses ruby's threading model to run listeners in parallel 
  # and in the background
  # Default: 3 threads
  config.threads = 3
end
```

## Usage

### Concepts
#### Publishers
**Publisher** is a mixin you can add into controllers, models and services to
produce events to be consumed by other parts of your application or other
microservices in your landscape.

##### Usage
```ruby
class User < ApplicationModel
  include Nagare::Publisher
  stream 'users'

  after_commit :publish_event

  def publish_event
    publish(user_updated: self.id)
  end
end
```

#### Listeners
**Listener** is a new first class citizen in the Rails world like models and 
controllers. They receive events from Redis Stream Groups and process them.
##### Usage
```ruby
class UserListener < Nagare::Listener
  stream 'users'

  def user_updated(event)
    user = User.find(event.data)
    Mailchimp.update_user(user)
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/vavato-be/nagare. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/vavato-be/nagare/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Nagare project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/vavato-be/nagare/blob/master/CODE_OF_CONDUCT.md).
