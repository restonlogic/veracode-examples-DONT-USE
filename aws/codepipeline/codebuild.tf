
data "aws_caller_identity" "this" {}

resource "random_id" "this" {
  byte_length = 8
}

resource "aws_s3_bucket" "bucket" {
  bucket        = "${var.git_config.gitops_org}-${var.global_config.environment}-${random_id.this.dec}"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "cbl-acl" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
}

# Lambda

resource "aws_codebuild_project" "lambda" {
  name          = "lambda-build"
  description   = "Codebuild for applying lambda"
  build_timeout = "5"
  service_role  = aws_iam_role.code-build-role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.bucket.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:1.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "BUILD_DIR"
      value = "./aws/codepipeline/lambda"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.bucket.id}/lambda/codebuild"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "./buildspecs/buildspec_lambda.yml"
  }

  vpc_config {
    vpc_id = aws_vpc.main.id

    subnets = [
      aws_subnet.subnet2.id
    ]

    security_group_ids = [
      aws_security_group.sg1.id,
      aws_security_group.sg2.id,
    ]
  }
}

# Veracode

resource "aws_codebuild_project" "veracode" {
  name          = "veracode-scan"
  description   = "Codebuild for scanning with veracode"
  build_timeout = "5"
  service_role  = aws_iam_role.code-build-role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.bucket.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "veracode/api-wrapper-java"
    type                        = "LINUX_CONTAINER"

    environment_variable {
      name  = "BUILD_DIR"
      value = "./aws/codepipeline/lambda"
    }

    environment_variable {
      name  = "VID"
      value = var.veracode_api_id
    }

    environment_variable {
      name  = "VKEY"
      value = var.veracode_api_key
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.bucket.id}/veracode/codebuild"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "./buildspecs/buildspec_vera.yml"
  }

  vpc_config {
    vpc_id = aws_vpc.main.id

    subnets = [
      aws_subnet.subnet2.id
    ]

    security_group_ids = [
      aws_security_group.sg1.id,
      aws_security_group.sg2.id,
    ]
  }
}