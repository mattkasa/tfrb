require 'aws-sdk'

module Tfrb::Resource::AwsIamRole
  extend Tfrb::Resource

  Tfrb::Block.send(:define_method, :sts_assume_role) do |service|
    role = <<-ROLE
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "#{service}.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
    ROLE
    role
  end

  def self.load(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      client = ::Aws::IAM::Client.new(aws_options(base, resource))
      begin
        response = client.get_role({
          role_name: resource['name']
        })
        id = response.role.role_name
        import!(base, resource_type, resource_name, id)
      rescue ::Aws::IAM::Errors::NoSuchEntity
        # Does not exist to import
      end
    end
  end
end
