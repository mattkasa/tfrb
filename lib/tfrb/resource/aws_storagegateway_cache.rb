require 'aws-sdk'

module Tfrb::Resource::AwsStoragegatewayCache
  extend Tfrb::Resource

  def self.load(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      client = ::Aws::StorageGateway::Client.new(aws_options(base, resource))
      disk_id = resolve_tfvar(base, resource_type, resource_name, 'disk_id')
      gateway_arn = resolve_tfvar(base, resource_type, resource_name, 'gateway_arn')
      next if disk_id.empty? || gateway_arn.empty?
      response = client.describe_cache({
        gateway_arn: gateway_arn
      })
      if response.disk_ids && response.disk_ids.include?(disk_id)
        id = "#{gateway_arn}:#{disk_id}"
        import!(base, resource_type, resource_name, id)
      end
    end
  end
end
