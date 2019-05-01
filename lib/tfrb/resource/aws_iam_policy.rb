require 'aws-sdk'

module Tfrb::Resource::AwsIamPolicy
  extend Tfrb::Resource

  Tfrb::Block.send(:define_method, :s3_replication_policy) do |bucket|
    policy = <<-POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListAllMyBuckets"
      ],
      "Resource": "arn:aws:s3:::*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::#{bucket}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:GetObject",
        "s3:GetObjectAcl",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::#{bucket}/*"
      ]
    }
  ]
}
    POLICY
    policy
  end

  Tfrb::Block.send(:define_method, :s3_replication_policy) do |source_bucket, destination_bucket|
    policy = <<-POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::#{source_bucket}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersion",
        "s3:GetObjectVersionAcl"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::#{source_bucket}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::#{destination_bucket}/*"
    }
  ]
}
    POLICY
    policy
  end

  Tfrb::Block.send(:define_method, :sgw_bucket_access_policy) do |bucket|
    policy = <<-POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetAccelerateConfiguration",
        "s3:GetBucketLocation",
        "s3:GetBucketVersioning",
        "s3:ListBucket",
        "s3:ListBucketVersions",
        "s3:ListBucketMultipartUploads"
      ],
      "Resource": "arn:aws:s3:::#{bucket}",
      "Effect": "Allow"
    },
    {
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:DeleteObject",
        "s3:DeleteObjectVersion",
        "s3:GetObject",
        "s3:GetObjectAcl",
        "s3:GetObjectVersion",
        "s3:ListMultipartUploadParts",
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": "arn:aws:s3:::#{bucket}/*",
      "Effect": "Allow"
    }
  ]
}
    POLICY
    policy
  end

  def self.load(base, environment_name, resource_type, new_resources)
    new_resources.each do |resource_name, resource|
      client = ::Aws::IAM::Client.new(aws_options(base, resource))
      begin
        response = client.list_policies({
          scope: 'Local',
          path_prefix: '/',
          max_items: 1000
        })
        if policy = response.policies.find { |p| p.arn =~ /policy\/#{resource_name}$/ }
          id = policy.arn
          import!(base, resource_type, resource_name, id)
        end
      rescue ::Aws::IAM::Errors::NoSuchEntity
        # Does not exist to import
      end
    end
  end
end
