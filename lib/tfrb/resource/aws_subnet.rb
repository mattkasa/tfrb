require 'aws-sdk'

module Tfrb::Resource::AwsSubnet
  extend Tfrb::Resource

  def self.load(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      client = ::Aws::EC2::Client.new(aws_options(base, resource))
      response = client.describe_subnets({
        filters: [
          {
            name: "tag:Name",
            values: [resource_name],
          },
          {
            name: "cidr-block",
            values: [resource['cidr_block']],
          },
        ],
        dry_run: false,
      })
      if response.subnets.size >= 1
        id = response.subnets.first.subnet_id
        import!(base, resource_type, resource_name, id)
      end
    end
  end
end
