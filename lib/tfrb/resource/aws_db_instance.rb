require 'aws-sdk'

module Tfrb::Resource::AwsDbInstance
  extend Tfrb::Resource

  def self.preload(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      set_default(resource, 'identifier', resource_name)
      set_default(resource, 'backup_window', '07:00-08:00')
      set_default(resource, 'backup_retention_period', 30)
      set_default(resource, 'deletion_protection', true)
      set_default(resource, 'maintenance_window', 'sat:08:00-sat:09:00')
      set_default(resource, 'multi_az', false)
      set_default(resource, 'publicly_accessible', false)
    end
  end

  def self.load(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      client = ::Aws::RDS::Client.new(aws_options(base, resource))
      begin
        response = client.describe_db_instances({
          db_instance_identifier: resource_name
        })
        id = response.db_instances.first.db_instance_identifier
        import!(base, resource_type, resource_name, id)
      rescue ::Aws::RDS::Errors::DBInstanceNotFound
        # Does not exist to import
      end
    end
  end
end
