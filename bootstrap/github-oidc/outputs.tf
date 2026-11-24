output "github_plan_role_arn" {
  description = "IAM Role ARN used by GitHub Actions to run Terraform Plan"
  value       = aws_iam_role.github_plan.arn
}

output "github_oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.github.arn
}