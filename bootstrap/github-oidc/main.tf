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