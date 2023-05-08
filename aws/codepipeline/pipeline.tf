resource "aws_codepipeline" "codepipeline" {
  name     = "lambda-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.bucket.bucket
    type     = "S3"

    encryption_key {
      id   = aws_kms_key.s3key.arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner                = var.git_config.gitops_org
        Repo                 = var.git_config.gitops_repo
        Branch               = var.git_config.gitops_branch
        OAuthToken           = var.git_token
        PollForSourceChanges = "True"
      }
    }
  }

  stage {
    name = "Security"

    action {
      name             = "Scanning"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output_scan"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.veracode.name
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output_build"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.lambda.name
      }
    }
  }
}