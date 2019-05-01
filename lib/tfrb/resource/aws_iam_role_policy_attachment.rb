require 'aws-sdk'

module Tfrb::Resource::AwsIamRolePolicyAttachment
  extend Tfrb::Resource

  def self.load(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      client = ::Aws::IAM::Client.new(aws_options(base, resource))
      role_name = resolve_tfvar(base, resource_type, resource_name, 'role')
      next if role_name.empty?
      begin
        response = client.list_attached_role_policies({
          role_name: role_name
        })
        if response.attached_policies
          response.attached_policies.each do |attached_policy|
            next unless attached_policy.policy_arn == resolve_tfvar(base, resource_type, resource_name, 'policy_arn')
            id = "#{role_name}/#{attached_policy.policy_arn}"
            import!(base, resource_type, resource_name, id)
          end
        end
      rescue ::Aws::IAM::Errors::NoSuchEntity, NoMethodError
        # Does not exist to import
      end
    end
  end
end
