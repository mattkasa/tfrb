require 'aws-sdk'

module Tfrb::Resource::AwsElasticacheSubnetGroup
  extend Tfrb::Resource

  def self.preload(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      set_default(resource, 'name', resource_name.gsub('_', ' '))
    end
  end

  def self.load(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      client = ::Aws::ElastiCache::Client.new(aws_options(base, resource))
      begin
        response = client.describe_cache_subnet_groups({
          cache_subnet_group_name: resource_name
        })
        if response.cache_subnet_groups.size >= 1
          id = response.cache_subnet_groups.first.cache_subnet_group_name
          import!(base, resource_type, resource_name, id)
        end
      rescue ::Aws::ElastiCache::Errors::CacheSubnetGroupNotFoundFault
        # Does not exist to import
      end
    end
  end
end
