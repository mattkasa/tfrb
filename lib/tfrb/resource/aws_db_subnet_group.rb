require 'aws-sdk'

module Tfrb::Resource::AwsDbSubnetGroup
  extend Tfrb::Resource

  def self.preload(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      resource['tags'] = {} unless resource.has_key?('tags')
      resource['tags']['Name'] = resource_name unless resource['tags'].has_key?('Name')
      set_default(resource, 'name', resource_name)
    end
  end

  def self.load(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      client = ::Aws::RDS::Client.new(aws_options(base, resource))
      begin
        response = client.describe_db_subnet_groups({
          db_subnet_group_name: resource_name
        })
        id = response.db_subnet_groups.first.db_subnet_group_name
        import!(base, resource_type, resource_name, id)
      rescue ::Aws::RDS::Errors::DBSubnetGroupNotFoundFault
        # Does not exist to import
      end
    end
  end
end
