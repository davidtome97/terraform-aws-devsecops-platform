# checkov:skip=CKV_AWS_144:Cross-region replication is intentionally not enabled for this low-cost single-region lab
# checkov:skip=CKV2_AWS_62:Event notifications are not required for the Terraform remote state bucket
resource "aws_s3_bucket" "terraform_state" {
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

resource "aws_kms_key" "terraform_state" {
  description             = "KMS key for Terraform remote state"
  deletion_window_in_days = 7
  enable_key_rotation     = true

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
  bucket = aws_s3_bucket.terraform_state_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  target_bucket = aws_s3_bucket.terraform_state_logs.id
  target_prefix = "state-access-logs/"

  depends_on = [
    aws_s3_bucket_public_access_block.terraform_state_logs
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