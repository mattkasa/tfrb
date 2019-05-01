require 'aws-sdk'

module Tfrb::Resource::AwsEbsVolume
  extend Tfrb::Resource

  def self.preload(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      resource['tags'] = {} unless resource.has_key?('tags')
      resource['tags']['Name'] = resource_name unless resource['tags'].has_key?('Name')
    end
  end

  def self.load(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      client = ::Aws::EC2::Client.new(aws_options(base, resource))
      response = client.describe_volumes({
        filters: [
          {
            name: "tag:Name",
            values: [
              resource_name,
            ],
          },
        ],
      })
      if response.volumes && response.volumes.size >= 1
        id = response.volumes.first.volume_id
        import!(base, resource_type, resource_name, id)
      end
    end
  end
end
