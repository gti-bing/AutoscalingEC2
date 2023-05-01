resource "aws_codepipeline" "static_web_pipeline" {
  name     = "codepipeline-demo"
  role_arn = "arn:aws:iam::954220424994:role/codepipeline-role-demo-project"
  tags     = {
    Environment = "demo"
  }

  artifact_store {
    location = "codepipeline-us-west-2-1"
    type     = "S3"
  }

  stage {
      name = "Source"

      action {
        name             = "Source"
        category         = "Source"
        owner            = "AWS"
        provider         = "CodeStarSourceConnection"
        version          = "1"
        output_artifacts = ["SourceArti"]

        configuration = {
          ConnectionArn    = "arn:aws:codestar-connections:us-east-1:954220424994:connection/b82aa852-a9dc-4b56-9100-6b0d2a391b4d"
          FullRepositoryId = "aikene/microbiome-project-ui"
          BranchName       = "ci-cd-deploy"
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
        input_artifacts  = ["SourceArti"]
        output_artifacts = ["BuildArtif"]
        version          = "1"

        configuration = {
          ProjectName = "demo-project"
        }
      }
    }

    stage {
      name = "Deploy"

      action {
        name            = "Deploy"
        category        = "Deploy"
        owner           = "AWS"
        provider        = "CodeDeploy"
        version         = "1"
        input_artifacts  = ["BuildArtif"]


        configuration = {
          ApplicationName     = "codedeploy-demo-app"
          DeploymentGroupName   = "deployment-grpname-demo"
          
        }
      }
    }
  }