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
  # checkov:skip=CKV_AWS_356:Wildcard resources are required for EC2 Describe actions, CloudWatch Logs DescribeLogGroups, and KMS CreateKey. KMS key creation is additionally constrained by the Project request tag.


  # ----------------------------------------------------------
  # EC2 / VPC - READ
  # ----------------------------------------------------------

  statement {
    sid    = "ReadEC2AndNetworking"
    effect = "Allow"

    actions = [
      "ec2:Describe*"
    ]

    resources = ["*"]
  }

  # ----------------------------------------------------------
  # EC2 / VPC - CREATE NETWORK RESOURCES
  # ----------------------------------------------------------

  statement {
    sid    = "CreateProjectNetworkResources"
    effect = "Allow"

    actions = [
      "ec2:CreateVpc",
      "ec2:CreateSubnet",
      "ec2:CreateInternetGateway",
      "ec2:CreateRouteTable",
      "ec2:CreateSecurityGroup"
    ]

    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:subnet/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:internet-gateway/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:route-table/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Project"

      values = [
        var.github_repository
      ]
    }
  }

  # ----------------------------------------------------------
  # EC2 / VPC - MANAGE PROJECT RESOURCES
  # ----------------------------------------------------------

  statement {
    sid    = "ManageExistingProjectEC2Resources"
    effect = "Allow"

    actions = [
      "ec2:DeleteVpc",
      "ec2:ModifyVpcAttribute",

      "ec2:DeleteSubnet",
      "ec2:ModifySubnetAttribute",

      "ec2:DeleteInternetGateway",

      "ec2:DeleteRouteTable",

      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupEgress",

      "ec2:TerminateInstances",
      "ec2:StartInstances",
      "ec2:StopInstances",

      "ec2:DeleteFlowLogs"
    ]

    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:subnet/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:internet-gateway/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:route-table/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc-flow-log/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Project"

      values = [
        var.github_repository
      ]
    }
  }

  # ----------------------------------------------------------
  # EC2 / VPC - ROUTING
  # ----------------------------------------------------------

  statement {
    sid    = "ManageProjectRouting"
    effect = "Allow"

    actions = [
      "ec2:AttachInternetGateway",
      "ec2:DetachInternetGateway",

      "ec2:CreateRoute",
      "ec2:ReplaceRoute",
      "ec2:DeleteRoute",

      "ec2:AssociateRouteTable",
      "ec2:DisassociateRouteTable"
    ]

    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:internet-gateway/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:route-table/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:subnet/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Project"

      values = [
        var.github_repository
      ]
    }
  }

  # ----------------------------------------------------------
  # EC2 - RUN INSTANCES
  # ----------------------------------------------------------

  statement {
    sid    = "RunProjectEC2Instances"
    effect = "Allow"

    actions = [
      "ec2:RunInstances"
    ]

    resources = [
      # Ubuntu AMI de Canonical
      "arn:aws:ec2:${var.aws_region}::image/*",

      # Recursos necesarios para lanzar la instancia
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:subnet/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:network-interface/*",

      # Recursos creados por RunInstances
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:volume/*"
    ]
  }

  # ----------------------------------------------------------
  # EC2 - TAG PROJECT RESOURCES
  # ----------------------------------------------------------

  statement {
    sid    = "ManageProjectEC2Tags"
    effect = "Allow"

    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags"
    ]

    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:subnet/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:internet-gateway/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:route-table/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:volume/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:network-interface/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc-flow-log/*"
    ]
  }

  # ----------------------------------------------------------
  # EC2 - VPC FLOW LOGS
  # ----------------------------------------------------------

  statement {
    sid    = "CreateProjectVPCFlowLogs"
    effect = "Allow"

    actions = [
      "ec2:CreateFlowLogs"
    ]

    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc-flow-log/*"
    ]
  }

  # ----------------------------------------------------------
  # IAM - PROJECT RESOURCES
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
  # CLOUDWATCH LOGS - READ
  # ----------------------------------------------------------

  statement {
    sid    = "ReadCloudWatchLogs"
    effect = "Allow"

    actions = [
      "logs:DescribeLogGroups"
    ]

    resources = ["*"]
  }

  # ----------------------------------------------------------
  # CLOUDWATCH LOGS - PROJECT RESOURCES
  # ----------------------------------------------------------

  statement {
    sid    = "ManageProjectCloudWatchLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:ListTagsForResource",
      "logs:TagResource",
      "logs:UntagResource",
      "logs:PutRetentionPolicy",
      "logs:DeleteRetentionPolicy",
      "logs:AssociateKmsKey",
      "logs:DisassociateKmsKey"
    ]

    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/vpc/${var.github_repository}-*"
    ]
  }

  # ----------------------------------------------------------
  # KMS - CREATE PROJECT KEYS
  # ----------------------------------------------------------

  statement {
    sid    = "CreateProjectKMSKeys"
    effect = "Allow"

    actions = [
      "kms:CreateKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Project"

      values = [
        var.github_repository
      ]
    }
  }

  # ----------------------------------------------------------
  # KMS - MANAGE PROJECT KEYS
  # ----------------------------------------------------------

  statement {
    sid    = "ManageProjectKMSKeys"
    effect = "Allow"

    actions = [
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

    resources = [
      "arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Project"

      values = [
        var.github_repository
      ]
    }
  }
}

# ============================================================
# ATTACH INFRASTRUCTURE POLICY TO DEPLOY ROLE
# ============================================================

resource "aws_iam_role_policy" "github_deploy_infrastructure" {
  name   = "terraform-infrastructure-deploy"
  role   = aws_iam_role.github_deploy.id
  policy = data.aws_iam_policy_document.github_deploy_infrastructure.json
}