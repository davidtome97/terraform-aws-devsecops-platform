# ============================================================
# GITHUB ACTIONS OIDC PROVIDER
# ============================================================

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]
}

# ============================================================
# AWS ACCOUNT INFORMATION
# ============================================================

data "aws_caller_identity" "current" {}

# ============================================================
# PLAN ROLE - TRUST POLICY
# ============================================================

data "aws_iam_policy_document" "github_plan_assume_role" {
  statement {
    sid     = "AllowGitHubActions"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"

      identifiers = [
        aws_iam_openid_connect_provider.github.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"

      values = [
        "sts.amazonaws.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        "repo:${var.github_owner}@25766791/${var.github_repository}@1463842042:pull_request"
      ]
    }
  }
}

# ============================================================
# GITHUB ACTIONS - TERRAFORM PLAN ROLE
# ============================================================

resource "aws_iam_role" "github_plan" {
  name = "terraform-github-plan"

  assume_role_policy = data.aws_iam_policy_document.github_plan_assume_role.json

  max_session_duration = 3600

  tags = {
    Name    = "terraform-github-plan"
    Project = var.github_repository
    Purpose = "github-actions-terraform-plan"
  }
}

# ============================================================
# PLAN ROLE - AWS READ ONLY
# ============================================================

resource "aws_iam_role_policy_attachment" "github_plan_read_only" {
  role       = aws_iam_role.github_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ============================================================
# PLAN ROLE - TERRAFORM STATE ACCESS
# ============================================================

data "aws_iam_policy_document" "github_plan_state" {
  statement {
    sid    = "ListStateBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${var.terraform_state_bucket}"
    ]
  }

  statement {
    sid    = "ReadTerraformState"
    effect = "Allow"

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "arn:aws:s3:::${var.terraform_state_bucket}/${var.terraform_state_key}"
    ]
  }

  statement {
    sid    = "DecryptTerraformState"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]

    resources = [
      var.terraform_state_kms_key_arn
    ]
  }
}

resource "aws_iam_role_policy" "github_plan_state" {
  name   = "terraform-state-read"
  role   = aws_iam_role.github_plan.id
  policy = data.aws_iam_policy_document.github_plan_state.json
}

# ============================================================
# DEPLOY ROLE - TRUST POLICY
# ============================================================

data "aws_iam_policy_document" "github_deploy_assume_role" {
  statement {
    sid     = "AllowGitHubActionsDeploy"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"

      identifiers = [
        aws_iam_openid_connect_provider.github.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"

      values = [
        "sts.amazonaws.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        "repo:${var.github_owner}@25766791/${var.github_repository}@1463842042:ref:refs/heads/main"
      ]
    }
  }
}

# ============================================================
# GITHUB ACTIONS - TERRAFORM DEPLOY ROLE
# ============================================================

resource "aws_iam_role" "github_deploy" {
  name = "terraform-github-deploy"

  assume_role_policy = data.aws_iam_policy_document.github_deploy_assume_role.json

  max_session_duration = 3600

  tags = {
    Name    = "terraform-github-deploy"
    Project = var.github_repository
    Purpose = "github-actions-terraform-deploy"
  }
}

# ============================================================
# DEPLOY ROLE - TERRAFORM STATE ACCESS
# ============================================================

data "aws_iam_policy_document" "github_deploy_state" {
  statement {
    sid    = "ListStateBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${var.terraform_state_bucket}"
    ]
  }

  statement {
    sid    = "ManageTerraformState"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "arn:aws:s3:::${var.terraform_state_bucket}/${var.terraform_state_key}",
      "arn:aws:s3:::${var.terraform_state_bucket}/${var.terraform_state_key}.tflock"
    ]
  }

  statement {
    sid    = "UseTerraformStateKMSKey"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]

    resources = [
      var.terraform_state_kms_key_arn
    ]
  }
}

resource "aws_iam_role_policy" "github_deploy_state" {
  name   = "terraform-state-write"
  role   = aws_iam_role.github_deploy.id
  policy = data.aws_iam_policy_document.github_deploy_state.json
}

# ============================================================
# DEPLOY ROLE - INFRASTRUCTURE PERMISSIONS
# ============================================================

data "aws_iam_policy_document" "github_deploy_infrastructure" {

  # ----------------------------------------------------------
  # EC2 / VPC
  # ----------------------------------------------------------

  statement {
    sid    = "ManageEC2AndNetworking"
    effect = "Allow"

    actions = [
      "ec2:Describe*",

      "ec2:CreateVpc",
      "ec2:DeleteVpc",
      "ec2:ModifyVpcAttribute",

      "ec2:CreateSubnet",
      "ec2:DeleteSubnet",
      "ec2:ModifySubnetAttribute",

      "ec2:CreateInternetGateway",
      "ec2:DeleteInternetGateway",
      "ec2:AttachInternetGateway",
      "ec2:DetachInternetGateway",

      "ec2:CreateRouteTable",
      "ec2:DeleteRouteTable",
      "ec2:CreateRoute",
      "ec2:ReplaceRoute",
      "ec2:DeleteRoute",
      "ec2:AssociateRouteTable",
      "ec2:DisassociateRouteTable",

      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupEgress",

      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:CreateTags",
      "ec2:DeleteTags",

      "ec2:CreateFlowLogs",
      "ec2:DeleteFlowLogs"
    ]

    resources = ["*"]
  }

  # ----------------------------------------------------------
  # IAM
  # ----------------------------------------------------------

  statement {
    sid    = "ManageTerraformIAMResources"
    effect = "Allow"

    actions = [
      "iam:GetRole",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",

      "iam:GetRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",

      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",

      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:GetInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:TagInstanceProfile",
      "iam:UntagInstanceProfile",

      "iam:PassRole"
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.github_repository}-*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${var.github_repository}-*"
    ]
  }

  # ----------------------------------------------------------
  # CLOUDWATCH LOGS
  # ----------------------------------------------------------

  statement {
    sid    = "ManageCloudWatchLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:DescribeLogGroups",
      "logs:ListTagsForResource",
      "logs:TagResource",
      "logs:UntagResource",
      "logs:PutRetentionPolicy",
      "logs:DeleteRetentionPolicy",
      "logs:AssociateKmsKey",
      "logs:DisassociateKmsKey"
    ]

    resources = ["*"]
  }

  # ----------------------------------------------------------
  # KMS
  # ----------------------------------------------------------

  statement {
    sid    = "ManageFlowLogsKMS"
    effect = "Allow"

    actions = [
      "kms:CreateKey",
      "kms:DescribeKey",
      "kms:GetKeyPolicy",
      "kms:PutKeyPolicy",
      "kms:EnableKeyRotation",
      "kms:GetKeyRotationStatus",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ListResourceTags"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_deploy_infrastructure" {
  name   = "terraform-infrastructure-deploy"
  role   = aws_iam_role.github_deploy.id
  policy = data.aws_iam_policy_document.github_deploy_infrastructure.json
}