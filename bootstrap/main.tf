resource "aws_s3_bucket" "terraform_state" {
  # checkov:skip=CKV_AWS_144:Cross-region replication is intentionally not enabled for this low-cost single-region lab
  # checkov:skip=CKV2_AWS_62:Event notifications are not required for the Terraform remote state bucket
  bucket = var.state_bucket_name

  tags = {
    Name    = "Terraform Remote State"
    Project = "terraform-aws-devsecops-platform"
    Purpose = "terraform-state"
  }
}

resource "aws_s3_bucket" "terraform_state_logs" {
  # checkov:skip=CKV_AWS_18:This bucket is the access logging destination and does not log to itself
  # checkov:skip=CKV_AWS_144:Cross-region replication is intentionally not enabled for this low-cost lab
  # checkov:skip=CKV2_AWS_62:Event notifications are not required for this access logging bucket

  bucket = "${var.state_bucket_name}-logs"

  tags = {
    Name    = "Terraform State Access Logs"
    Project = "terraform-aws-devsecops-platform"
    Purpose = "terraform-state-access-logs"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "terraform-state-lifecycle"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.terraform_state
  ]
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "terraform_state" {
  description             = "KMS key for Terraform remote state"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "EnableRootPermissions"
        Effect = "Allow"

        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }

        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = {
    Name    = "terraform-state-kms"
    Project = "terraform-aws-devsecops-platform"
    Purpose = "terraform-state-encryption"
  }
}

resource "aws_kms_alias" "terraform_state" {
  name          = "alias/terraform-state"
  target_key_id = aws_kms_key.terraform_state.key_id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform_state.arn
    }

    bucket_key_enabled = true
  }
}

# ============================================================
# S3 ACCESS LOGGING
# ============================================================

resource "aws_s3_bucket_public_access_block" "terraform_state_logs" {
  bucket = aws_s3_bucket.terraform_state_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "terraform_state_logs" {
  bucket = aws_s3_bucket.terraform_state_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_logs" {
  # checkov:skip=CKV_AWS_145:S3 server access logging destination requires SSE-S3; SSE-KMS is not supported for direct S3 log delivery
  bucket = aws_s3_bucket.terraform_state_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "terraform_state_logs" {
  statement {
    sid    = "AllowS3ServerAccessLogging"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.terraform_state_logs.arn}/state-access-logs/*"
    ]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"

      values = [
        aws_s3_bucket.terraform_state.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"

      values = [
        data.aws_caller_identity.current.account_id
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "terraform_state_logs" {
  bucket = aws_s3_bucket.terraform_state_logs.id
  policy = data.aws_iam_policy_document.terraform_state_logs.json
}

resource "aws_s3_bucket_logging" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  target_bucket = aws_s3_bucket.terraform_state_logs.id
  target_prefix = "state-access-logs/"

  depends_on = [
    aws_s3_bucket_public_access_block.terraform_state_logs,
    aws_s3_bucket_policy.terraform_state_logs
  ]
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform_state_logs" {
  bucket = aws_s3_bucket.terraform_state_logs.id

  rule {
    id     = "access-logs-lifecycle"
    status = "Enabled"

    filter {}

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.terraform_state_logs
  ]
}