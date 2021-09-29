# PopuliAPI

A very simple, unofficial wrapper for the [Populi](https://populi.co/) API ([official docs][api-ref]).

Built by the folks at [Turing School](https://turing.edu).

[![CircleCI](https://circleci.com/gh/turingschool/populi_api/tree/main.svg?style=shield)](https://circleci.com/gh/turingschool/populi_api/tree/main)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'populi_api', git: 'https://github.com/turingschool/populi_api.git', branch: 'main'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install populi_api

## Usage

Any task in the [reference][api-ref] can be called as a method on the `PopuliAPI` module.

Keyword arguments supplied will be converted into the params for the API call.

```ruby
require "populi_api"

# Establish a connection
PopuliAPI.connect(
  url: ENV["POPULI_API_URL"],               # e.g. https://yourschool.populiweb.com/api/
  access_key: ENV["POPULI_API_ACCESS_KEY"]  # see "Authorization" section below
)

PopuliAPI.get_person(person_id: 1)
# => {
#      "response"=> {
#        "first"=>"James 'Logan'",
#        "last"=>"Howlett",
#        "middle_name"=>nil,
#        "preferred_name"=>"Wolverine",
#        "email"=>
#        {"emailid"=>"20482815",
#          "type"=>"OTHER",
#          "address"=>"wolverine@xmansion.edu",
#          "is_primary"=>"1",
#          "no_mailings"=>"0"},
#        "status"=>"ACTIVE",
#        "gender"=>"UNKNOWN",
#        ...
#      }
#    }
```

It treats `camelCase` and `snake_case` formats as equivalent, so you can use either:

```ruby
PopuliAPI.get_person == PopuliAPI.getPerson
```

The XML response is parsed into an [ActiveSupport::HashWithIndifferentAccess](https://api.rubyonrails.org/classes/ActiveSupport/HashWithIndifferentAccess.html), so you can traverse it using strings or symbols for keys. Up to you.

```ruby
response = PopuliAPI.get_person(person_id: 1)

person = response[:response]
person[:first]               # => "James 'Logan'"
person["email"]["address"]   # => "wolverine@xmansion.edu"
```

### Authorization

All requests require an API `access_key`. You'll need to pre-fetch this from the API using the [Access Key Request Structure](https://support.populiweb.com/hc/en-us/articles/223798787-API-Basics).

### Rate Limiting

All requests are configured to use rate limiting middleware that abides by [Populi's rate limiting policy](https://support.populiweb.com/hc/en-us/articles/223798787-API-Basics).

As an end-user, this will appear as a slight enforced delay for requests when the requests-per-minute limit is reached.

### Errors

If a request to the API fails in a predictable way, Populi will return a non-200 status code HTTP response (usually 400) with XML describing the error. See the [API Basics docs](https://support.populiweb.com/hc/en-us/articles/223798787-API-Basics) for more information.

When using the `PopuliAPI` request methods, you can choose to either have these error responses return the response body as expected, or to raise an exception. To have a request raise an exception on failure, append a `!` to the method.

```ruby
PopuliAPI.get_person(person_id: "not-an-id")
# => {"error"=>{"code"=>"BAD_PARAMETER", "message"=>"Please pass in a valid person_id or student_id"}}

PopuliAPI.get_person!(person_id: "not-an-id")
# => raises "PopuliAPI::BadParameterError (Please pass in a valid person_id or student_id)"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/turingschool/populi_api](https://github.com/turingschool/populi_api). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/turingschool/populi_api/blob/main/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the PopuliAPI project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/turingschool/populi_api/blob/main/CODE_OF_CONDUCT.md).

[api-ref]: https://support.populiweb.com/hc/en-us/articles/223798747-API-Reference
