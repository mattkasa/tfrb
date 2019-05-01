require 'aws-sdk'

module Tfrb::Resource::AwsS3Bucket
  extend Tfrb::Resource

  def self.load(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      client = ::Aws::S3::Client.new(aws_options(base, resource))
      begin
        response = client.head_bucket({
          bucket: resource['bucket']
        })
        id = resource['bucket']
        import!(base, resource_type, resource_name, id)
      rescue ::Aws::S3::Errors::NoSuchBucket, ::Aws::S3::Errors::NotFound
        # Does not exist to import
      end
    end
  end
end
