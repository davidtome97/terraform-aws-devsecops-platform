#!/bin/bash

set -e

apt-get update -y

echo "Terraform DevSecOps Platform" > /home/ubuntu/terraform-lab.txt
echo "EC2 configured automatically using Terraform User Data" >> /home/ubuntu/terraform-lab.txt

chown ubuntu:ubuntu /home/ubuntu/terraform-lab.txt