require 'aws-sdk'

module Tfrb::Resource::AwsVolumeAttachment
  extend Tfrb::Resource

  def self.preload(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      set_default(resource, 'volume_id', "${aws_ebs_volume.#{resource_name}.id}")
    end
  end

  def self.load(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      # client = ::Aws::EC2::Client.new(aws_options(base, resource))
      # response = client.describe_volumes({
      #   volume_ids: [
      #     resolve_tfvar(base, resource_type, resource_name, 'volume_id')
      #   ],
      # })
      # if response.volumes && response.volumes.size >= 1
      #   if response.volumes.first.attachments && response.volumes.first.attachments.size >= 1
      #     if response.volumes.first.attachments.find { |a| a.instance_id == resolve_tfvar(base, resource_type, resource_name, 'instance_id') }
      #       id = response.volumes.first.volume_id
      #       import!(base, resource_type, resource_name, id)
      #     end
      #   end
      # end
    end
  end
end
