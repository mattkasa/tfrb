require 'aws-sdk'

module Tfrb::Resource::AwsStoragegatewayGateway
  extend Tfrb::Resource

  def self.preload(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      set_default(resource, 'gateway_name', resource_name.gsub('_', ' '))
    end
  end

  def self.load(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      client = ::Aws::StorageGateway::Client.new(aws_options(base, resource))
      response = client.list_gateways({
        limit: 100
      })
      if response.gateways && gateway = response.gateways.find { |g| g.gateway_name == resource_name }
        id = gateway.gateway_arn
        import!(base, resource_type, resource_name, id)
      end
    end
  end
end
