require 'aws-sdk'

module Tfrb::Resource::AwsVpc
  extend Tfrb::Resource

  def self.load(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      client = ::Aws::EC2::Client.new(aws_options(base, resource))
      response = client.describe_vpcs({
        filters: [
          {
            name: "tag:Name",
            values: [resource_name],
          },
        ],
        dry_run: false,
      })
      if response.vpcs.size >= 1
        id = response.vpcs.first.vpc_id
        import!(base, resource_type, resource_name, id)
      end
    end
  end
end
