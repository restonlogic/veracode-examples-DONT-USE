resource "aws_s3_bucket" "cb-bucket" {
  bucket = "${var.org}-${var.env}-cb-${random_id.cb-id.dec}"
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.cb-bucket.id
  acl    = "private"
}

resource "aws_iam_role" "code-build-role" {
  name = "code-build-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cb-policy" {
  role = aws_iam_role.code-build-role.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterfacePermission"
      ],
      "Resource": [
        "arn:aws:ec2:us-east-1:${data.aws_caller_identity.my-id.account_id}:network-interface/*"
      ],
      "Condition": {
        "StringEquals": {
          "ec2:Subnet": [
            "${aws_subnet.subnet1.arn}",
            "${aws_subnet.subnet2.arn}"
          ],
          "ec2:AuthorizedService": "codebuild.amazonaws.com"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.cb-bucket.arn}",
        "${aws_s3_bucket.cb-bucket.arn}/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_codebuild_project" "codebuild-lambda" {
  name          = "lambda-build"
  description   = "test_codebuild_project"
  build_timeout = "5"
  service_role  = aws_iam_role.code-build-role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.cb-bucket.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:1.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "SOME_KEY1"
      value = "SOME_VALUE1"
    }

    environment_variable {
      name  = "SOME_KEY2"
      value = "SOME_VALUE2"
      type  = "PARAMETER_STORE"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.cb-bucket.id}/build-log"
    }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/${var.github-repo}.git"
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = true
    }
  }

  source_version = "master"

  vpc_config {
    vpc_id = aws_vpc.main.id

    subnets = [
      aws_subnet.subnet1.id,
      aws_subnet.subnet2.id,
    ]

    security_group_ids = [
      aws_security_group.sg1.id,
      aws_security_group.sg2.id,
    ]
  }

  tags = {
    Environment = "Test"
  }
}

data "aws_caller_identity" "my-id" {}

resource "random_id" "cb-id" {
  byte_length = 8
}