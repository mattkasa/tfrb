module Tfrb::Provider::Aws
  def self.load(base, environment)
    if environment.has_key?('provider') && environment['provider'].has_key?('aws')
      unless environment['provider']['aws'].has_key?('access_key') || environment['provider']['aws'].has_key?('secret_key') || environment['provider']['aws'].has_key?('token')
        environment['provider']['aws']['access_key'] = ENV['AWS_ACCESS_KEY_ID']
        environment['provider']['aws']['secret_key'] = ENV['AWS_SECRET_ACCESS_KEY']
        environment['provider']['aws']['token'] = ENV['AWS_SESSION_TOKEN']
      end
    end
  end
end
