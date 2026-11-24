#!/usr/bin/env bash

set -euo pipefail

echo "=========================================="
echo " Terraform Plan - DevSecOps Platform"
echo "=========================================="

echo ""
echo "Terraform version:"
terraform version

echo ""
echo "Initializing Terraform backend..."
terraform init -input=false

echo ""
echo "Validating Terraform configuration..."
terraform validate

echo ""
echo "Generating Terraform plan..."
terraform plan \
  -input=false \
  -lock=false \
  -no-color \
  -var-file=environments/dev.tfvars

echo ""
echo "=========================================="
echo " Terraform Plan completed successfully"
echo "=========================================="