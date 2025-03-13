# Terraform Configuration used for full integration test

variable "aws_vpc_security_group_ids" {
  type = list(string)
}

module "rubrik_aws_cloud_cluster_elastic_storage" {
  source = "../"

  aws_region                  = var.aws_region
  aws_disable_api_termination = false
  aws_vpc_security_group_ids  = var.aws_vpc_security_group_ids
  aws_subnet_id               = var.aws_subnet_id
  cluster_name                = "terraform-module-cloud-cluster-testing"
  admin_email                 = "build@rubrik.com"
  admin_password              = var.admin_password
  dns_search_domain           = ["rubrikbuild.com"]
  dns_name_servers            = ["8.8.8.8"]
  timeout                     = 30
  number_of_nodes             = 1
  create_iam_role             = true
  create_s3_bucket            = true
  create_s3_vpc_endpoint      = true
}
