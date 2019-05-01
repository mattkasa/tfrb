require 'aws-sdk'

module Tfrb::Resource::AwsSecurityGroup
  extend Tfrb::Resource

  def self.preload(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      set_default(resource, 'name', resource_name.gsub('_', ' '))
      resource['lifecycle'] = {} unless resource.has_key?('lifecycle')
      resource['lifecycle']['create_before_destroy'] = true unless resource['lifecycle'].has_key?('create_before_destroy')
      resource['tags'] = {} unless resource.has_key?('tags')
      resource['tags']['Name'] = resource_name.gsub('_', ' ') unless resource['tags'].has_key?('Name')
    end
  end

  def self.load(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      client = ::Aws::EC2::Client.new(aws_options(base, resource))
      vpc_id = resolve_tfvar(base, resource_type, resource_name, 'vpc_id')
      next if vpc_id.empty?
      response = client.describe_security_groups({
        filters: [
          {
            name: 'vpc-id',
            values: [vpc_id]
          },
          {
            name: 'group-name',
            values: [resource['name']]
          }
        ]
      })
      if response.security_groups.size >= 1
        id = response.security_groups.first.group_id
        import!(base, resource_type, resource_name, id)
      end
    end
  end
end
