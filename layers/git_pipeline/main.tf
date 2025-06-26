############################
######### GENERAL ##########
############################

resource "aws_iam_policy" "deployment" {
  count       = var.create_github_runners_codebuild ? 1 : 0
  name        = "policy-${var.env}-valkyrie-deployment"
  path        = "/"
  description = "Valkyrie deployment policy"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
          "Action": [
            "eks:DescribeCluster",
            "eks:ListClusters"
          ],
          "Resource": "*",
          "Effect": "Allow",
          "Sid": "EksDeployment"
        },
        {
          "Action": [
            "s3:ListBucket",
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:PutObject",
            "s3:PutObjectVersion",
            "s3:PutObjectAcl",
            "s3:PutObjectTagging",
            "s3:GetObjectTagging",
            "s3:GetObjectVersionTagging",
            "s3:AbortMultipartUpload",
            "s3:ListMultipartUploadParts",
            "s3:ListBucketMultipartUploads",
            "s3:GetObjectAcl",
            "s3:PutObjectVersionAcl",
            "s3:GetBucketLocation",
            "s3:ListAllMyBuckets"
          ],
          "Resource": "*",
          "Effect": "Allow",
          "Sid": "S3Deployment"
        },
        {
          "Action": "iam:PassRole",
          "Resource": "*",
          "Effect": "Allow",
          "Sid": "IAM"
        },
        {
          "Action": [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey",
            "kms:Describe*"
          ],
          "Resource": "*",
          "Effect": "Allow",
          "Sid": "KMS"
        },
        {
          "Action": [
            "ssm:DescribeParameters",
            "ssm:GetParametersByPath",
            "ssm:GetParameters",
            "ssm:GetParameter"
          ],
          "Resource": "*",
          "Effect": "Allow",
          "Sid": "SSM"
        },
        {
          "Action": [
            "cloudwatch:DescribeAlarms",
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource": "*",
          "Effect": "Allow",
          "Sid": "cloudwatch"
        },
        {
          "Action": [
            "ecr:GetDownloadUrlForLayer",
            "ecr:CompleteLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:InitiateLayerUpload",
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:PutImage",
            "ecr:BatchGetImage"
          ],
          "Resource": "*",
          "Effect": "Allow",
          "Sid": "ECR"
        },
        {
          "Action": [
            "tag:TagResources",
            "tag:UntagResources"
          ],
          "Resource": "*",
          "Effect": "Allow",
          "Sid": "Tag"
        }
    ]
  })
}

############################
# GITHUB RUNNERS CODEBUILD #
############################

locals {
  account_id = data.aws_caller_identity.this.account_id
}

module "codebuild_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.2.0"

  create = var.create_github_runners_codebuild

  name        = "sgr-${var.env}-codebuild-github-runners"
  description = "Codebuild GitHub Runners security group"
  vpc_id      = var.vpc_id

  # egress
  ingress_cidr_blocks       = ["0.0.0.0/0"]
  ingress_rules             = ["https-443-tcp"]

  # egress
  egress_cidr_blocks       = ["0.0.0.0/0"]
  egress_ipv6_cidr_blocks  = []
  egress_rules             = ["all-all"]
}

data "aws_iam_policy_document" "assume_role" {
  count = var.create_github_runners_codebuild ? 1 : 0
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


resource "aws_iam_role" "codebuild" {
  count              = var.create_github_runners_codebuild ? 1 : 0
  name               = "role-${var.env}-codebuild-github-runners"
  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json
}

resource "aws_iam_policy" "codebuild" {
  count  = var.create_github_runners_codebuild ? 1 : 0
  name   = "policy-${var.env}-codebuild-github-runners"
  policy = data.aws_iam_policy_document.codebuild[0].json
}

resource "aws_iam_policy_attachment" "codebuild" {
  count      = var.create_github_runners_codebuild ? 1 : 0
  name       = "codebuild"
  roles      = [aws_iam_role.codebuild[0].name]
  policy_arn = aws_iam_policy.codebuild[0].arn
}

resource "aws_iam_policy_attachment" "deployment" {
  count      = var.create_github_runners_codebuild ? 1 : 0
  name       = "deployment"
  roles      = [aws_iam_role.codebuild[0].name]
  policy_arn = aws_iam_policy.deployment[0].arn
}

data "aws_iam_policy_document" "codebuild" {
  count = var.create_github_runners_codebuild ? 1 : 0
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
    ]

    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:CreateNetworkInterfacePermission"]
    resources = ["arn:aws:ec2:${data.aws_region.current.name}:${local.account_id}:network-interface/*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:Subnet"

      # values = var.subnet_ids
      values = [
          "arn:aws:ec2:${data.aws_region.current.name}:${local.account_id}:subnet/${var.subnet_ids[0]}",
          "arn:aws:ec2:${data.aws_region.current.name}:${local.account_id}:subnet/${var.subnet_ids[1]}"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:AuthorizedService"
      values   = ["codebuild.amazonaws.com"]
    }
  }

  statement {
    effect  = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "codebuild:CreateReportGroup",
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutTestCases",
      "codebuild:BatchPutCodeCoverages"
    ]
    resources = ["arn:aws:codebuild:${data.aws_region.current.name}:${local.account_id}:report-group/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = ["*"]
  }
}

resource "aws_codebuild_project" "github-runners" {
  count          = var.create_github_runners_codebuild ? 1 : 0
  name           = "github-runners-${var.env}"
  build_timeout  = var.build_timeout
  queued_timeout = var.queued_timeout
  service_role   = aws_iam_role.codebuild[0].arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "NO_CACHE"
  }

  environment {
    compute_type                = var.compute_type
    image                       = var.image
    type                        = var.type
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = var.privileged_mode
  }

  logs_config {
    cloudwatch_logs {
      status   = "ENABLED"
    }

    s3_logs {
      status   = "DISABLED"
    }
  }

  source {
    type            = "GITHUB"
    location       = "CODEBUILD_DEFAULT_WEBHOOK_SOURCE_LOCATION"
    git_clone_depth = 1
    insecure_ssl    = false
    report_build_status = false
    git_submodules_config {
      fetch_submodules = false
    }
  }

  vpc_config {
    vpc_id = var.vpc_id
    subnets = var.subnet_ids
    security_group_ids = [
      module.codebuild_security_group.security_group_id
    ]
  }

}


data "aws_ssm_parameter" "pat" {
  name = "demo-github-pat"
  with_decryption = true
}

resource "aws_codebuild_source_credential" "this" {
  count       = var.create_github_runners_codebuild ? 1 : 0
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = data.aws_ssm_parameter.pat.value
}

resource "aws_codebuild_webhook" "this" {
  count           = var.create_github_runners_codebuild ? 1 : 0
  project_name    = aws_codebuild_project.github-runners[0].name
  manual_creation = false
  build_type      = "BUILD"
  filter_group {
    filter {
      type    = "EVENT"
      pattern = "WORKFLOW_JOB_QUEUED"
    }
  }
  scope_configuration {
    name  = var.github_organization_name
    scope = "GITHUB_ORGANIZATION"
  }
  depends_on   = [aws_codebuild_source_credential.this]
}