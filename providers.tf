terraform {
  required_version = ">= 1.2.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    polaris = {
      source  = "rubrikinc/polaris"
      version = "=0.8.0-beta.4"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

provider "polaris" {}
