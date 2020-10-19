terraform {
  required_version = ">= 0.12"
}
variable "github_token" {
    type = string
}
variable "site_name" {
    type = string
}
provider "aws" {
    profile = "default"
    region = "ap-southeast-2"
}
provider "github"{
    token = var.github_token
}
resource "aws_s3_bucket" "blog_bucket"{
    bucket = "${var.site_name}"
    acl = "public-read"
    force_destroy = true
    website {
        index_document = "index.html"
        error_document = "error.html"
        routing_rules = <<EOF
[{
    "Condition": {
        "KeyPrefixEquals": "docs/"
    },
    "Redirect": {
        "ReplaceKeyPrefixWith": "documents/"
    }
}]
EOF 
    }
}

data "aws_iam_policy_document" "blog_bucket_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.blog_bucket.bucket}/*"]
    effect = "Allow"
    principals {
      type = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "blog_bucket_policy" {
  bucket = aws_s3_bucket.blog_bucket.id
  policy = data.aws_iam_policy_document.blog_bucket_policy.json
}

resource "aws_iam_role" "codebuild_role" {
  name = var.site_name

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

resource "aws_iam_role_policy" "example" {
  role = aws_iam_role.codebuild_role.name

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
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
          "s3:GetObjectVersion"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_codebuild_project" "blog_codebuild" {
  name           = "serverless_blog"
  description    = "serverless_blog_codebuild_project"
  build_timeout  = "5"
  queued_timeout = "5"

  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:1.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

  }

  source {
    type            = "GITHUB"
    location        = github_repository.web_repo.html_url
    git_clone_depth = 1
  }
}

resource "github_repository" "web_repo"{
    name = var.site_name
    description = "serverless blog"
}

resource "aws_codebuild_webhook" "codebuild_webhook" {
  project_name = aws_codebuild_project.blog_codebuild.name
}

resource "aws_codebuild_source_credential" "github_cred" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = var.github_token
}