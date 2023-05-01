resource "aws_codebuild_project" "code_build" {
  name                          = "demo-project"
  description                   = "demo project created by terraform"
  build_timeout                 = "5"
  service_role                  = aws_iam_role.codebuild_service.arn
  artifacts {
    name                        = "demo-project"  
    type                        = "S3"
    path                        = "/"
    location                    = "codepipeline-us-west-2-1"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_LARGE"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = false
  }

  source {
    type                          = "GITHUB"
    location                      = "https://github.com/aikene/microbiome-project-ui.git"
    git_clone_depth               = "1"
    
  }

  tags = {
    Name                          = "demo-project"
  }
}



# create a service role for codebuild
resource "aws_iam_role" "codebuild_service" {
  name = "codebuild-demo-project-service-role"

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

resource "aws_iam_policy" "codebuild_policy" {
  name        = "CodeBuildBasePolicy-demo-project-us-west-2"
  path        = "/"
  description = "Policy used in trust relationship with CodeBuild"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:logs:us-west-2:954220424994:log-group:/aws/codebuild/demo-project",
                "arn:aws:logs:us-west-2:954220424994:log-group:/aws/codebuild/demo-project:*"
            ],
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::codepipeline-us-west-2-*"
            ],
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::codepipeline-us-west-2-1",
                "arn:aws:s3:::codepipeline-us-west-2-1/*"
            ],
            "Action": [
                "s3:PutObject",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "codebuild:CreateReportGroup",
                "codebuild:CreateReport",
                "codebuild:UpdateReport",
                "codebuild:BatchPutTestCases",
                "codebuild:BatchPutCodeCoverages"
            ],
            "Resource": [
                "arn:aws:codebuild:us-west-2:954220424994:report-group/demo-project-*"
            ]
        }
    ]
})
}

# attach newly created policy the codebuild service role
resource "aws_iam_role_policy_attachment" "codebuild_service" {
  role       = aws_iam_role.codebuild_service.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}