require 'aws-sdk'

module Tfrb::Resource::AwsDynamodbTable
  extend Tfrb::Resource

  def self.preload(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      set_default(resource, 'name', resource_name)
    end
  end

  def self.load(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      client = ::Aws::DynamoDB::Client.new(aws_options(base, resource))
      begin
        response = client.describe_table({
          table_name: resource_name
        })
        id = response.table.table_name
        import!(base, resource_type, resource_name, id)
      rescue ::Aws::DynamoDB::Errors::TableNotFoundException, ::Aws::DynamoDB::Errors::ResourceNotFoundException
        # Does not exist to import
      end
    end
  end
end
