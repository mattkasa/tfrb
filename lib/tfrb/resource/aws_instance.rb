require 'aws-sdk'

module Tfrb::Resource::AwsInstance
  extend Tfrb::Resource

  def self.preload(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      resource['tags'] = {} unless resource.has_key?('tags')
      resource['tags']['Name'] = resource_name unless resource['tags'].has_key?('Name')
      resource['root_block_device'] = {} unless resource.has_key?('root_block_device')
      resource['root_block_device']['volume_type'] = 'gp2' unless resource['root_block_device'].has_key?('volume_type')
      resource['root_block_device']['volume_size'] = 8 unless resource['root_block_device'].has_key?('volume_size')
    end
  end

  def self.load(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      client = ::Aws::EC2::Client.new(aws_options(base, resource))
      response = client.describe_instances({
        filters: [
          {
            name: 'tag:Name',
            values: [
              resource_name,
            ],
          },
          {
            name: 'instance-state-name',
            values: [
              'pending',
              'running',
              'stopping',
              'stopped'
            ],
          },
        ],
      })
      if response.reservations && response.reservations.size >= 1
        if response.reservations.first.instances && response.reservations.first.instances.size >= 1
          id = response.reservations.first.instances.first.instance_id
          import!(base, resource_type, resource_name, id)
        end
      end
    end
  end
end
