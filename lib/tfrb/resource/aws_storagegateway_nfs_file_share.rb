require 'aws-sdk'

module Tfrb::Resource::AwsStoragegatewayNfsFileShare
  extend Tfrb::Resource

  def self.load(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      client = ::Aws::StorageGateway::Client.new(aws_options(base, resource))
      gateway_arn = resolve_tfvar(base, resource_type, resource_name, 'gateway_arn')
      location_arn = resolve_tfvar(base, resource_type, resource_name, 'location_arn')
      next if gateway_arn.empty? || location_arn.empty?
      response = client.list_file_shares({
        gateway_arn: gateway_arn,
        limit: 100
      })
      if response.file_share_info_list && nfs_file_shares = response.file_share_info_list.select { |s| s.file_share_type == 'NFS' }.map { |s| s.file_share_arn }
        response = client.describe_nfs_file_shares({
          file_share_arn_list: nfs_file_shares
        })
        if response.nfs_file_share_info_list && file_share = response.nfs_file_share_info_list.find { |s| s.location_arn == location_arn }
          id = file_share.file_share_arn
          import!(base, resource_type, resource_name, id)
        end
      end
    end
  end
end
