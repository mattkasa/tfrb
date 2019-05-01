require 'aws-sdk'

module Tfrb::Resource::AwsKmsKey
  extend Tfrb::Resource

  def self.preload(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      set_default(resource, 'enable_key_rotation', true)
    end
  end

  def self.load(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      client = ::Aws::KMS::Client.new(aws_options(base, resource))
      begin
        response = client.describe_key({
          key_id: "alias/#{resource_name}"
        })
        id = response.key_metadata.key_id
        import!(base, resource_type, resource_name, id)
      rescue ::Aws::KMS::Errors::NotFoundException
        # Does not exist to import
      end
    end
  end
end
