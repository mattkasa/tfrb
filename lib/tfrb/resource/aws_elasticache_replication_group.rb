require 'aws-sdk'

module Tfrb::Resource::AwsElasticacheReplicationGroup
  extend Tfrb::Resource

  def self.preload(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      set_default(resource, 'snapshot_window', '07:00-08:00')
      set_default(resource, 'snapshot_retention_limit', '30')
      set_default(resource, 'maintenance_window', 'sat:08:00-sat:09:00')
    end
  end

  def self.load(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      client = ::Aws::ElastiCache::Client.new(aws_options(base, resource))
      begin
        response = client.describe_replication_groups({
          replication_group_id: resource['replication_group_id']
        })
        if response.replication_groups.size >= 1
          id = response.replication_groups.first.replication_group_id
          import!(base, resource_type, resource_name, id)
        end
      rescue ::Aws::ElastiCache::Errors::ReplicationGroupNotFoundFault
        # Does not exist to import
      end
    end
  end
end
