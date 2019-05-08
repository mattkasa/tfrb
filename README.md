# tfrb

Ruby DSL for Terraform

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tfrb'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tfrb

## Usage

    $ tfrm --help

## Configuration

tfrb is configured using a `tfrb.rb` file in the current working directory where you run `tfrb` similar to:

    ::Tfrb::Config[:environment_name] = 'dev'
    ::Tfrb::Config[:path] = ::File.join(::File.dirname(::Chef::Config.environment_path), 'infrastructure')
    ::Tfrb::Config[:temp_path] = ::File.join(::File.dirname(::Chef::Config.environment_path), '.infrastructure')
    ::Tfrb::Config[:files] = ::Chef::Config[:knife][:infrastructure_environments]

    ::Tfrb::Config[:extra_modules] = [
      Atlas::Aws,
      Atlas::Chef
    ]

    ::Tfrb::Config[:overrides] = {
      'provider' => {
        'aws' => {
          'access_key' => ::Chef::Config[:knife][:aws_access_key_id],
          'secret_key' => ::Chef::Config[:knife][:aws_secret_access_key],
          'token' => ::Chef::Config[:knife][:aws_session_token]
        }
      },
      'resource' => {}
    }

    # Require everything in lib/tfrb/resource/
    ::Dir[::File.join(::File.dirname(__FILE__), 'lib', 'tfrb', '*', '*.rb')].each { |file| require file }

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Granicus/tfrb.

Please feel free to fork and modify if it does not suit your needs!
