#############################
# Dynamic Variable Creation #
#############################
locals {
  cluster_node_names  = formatlist("${var.cluster_name}-%02s", range(1, var.number_of_nodes + 1))
  ami_id              = var.aws_image_id == "" || var.aws_image_id == "latest" ? data.aws_ami_ids.rubrik_cloud_cluster.ids[0] : var.aws_image_id
  sg_ids              = var.aws_cloud_cluster_nodes_sg_ids == "" ? [module.rubrik_nodes_sg.security_group_id] : concat(var.aws_cloud_cluster_nodes_sg_ids, [module.rubrik_nodes_sg.security_group_id])
  instance_type       = var.aws_instance_type
  enableImmutability  = var.enableImmutability ? 1 : 0
  ebs_throughput      = (var.cluster_disk_type == "gp3" ? 250 : null)   
  aws_key_pair_name   = var.aws_key_pair_name == "" ? module.aws_key_pair.key_pair_name : var.aws_key_pair_name
  cluster_node_config = {
    "instance_type"           = var.aws_instance_type,
    "ami_id"                  = local.ami_id,
    "sg_ids"                  = local.sg_ids,
    "subnet_id"               = var.aws_subnet_id,
    "key_pair_name"           = local.aws_key_pair_name,
    "disable_api_termination" = var.aws_disable_api_termination,
    "iam_instance_profile"    = var.aws_cloud_cluster_ec2_instance_profile_name == "" ? "${var.cluster_name}.instance-profile" : var.aws_cloud_cluster_ec2_instance_profile_name,
    "availability_zone"       = data.aws_subnet.rubrik_cloud_cluster.availability_zone,
    "tags"                    = var.aws_tags
    "root_volume_type"        = var.cluster_disk_type
    "root_volume_throughput"  = local.split_disk ? 125 : local.ebs_throughput
    "http_tokens"             = var.aws_instance_imdsv2 ? "required" : "optional"
  }

  cluster_node_ips = [for i in module.cluster_nodes.instances : i.private_ip]

  # Create 2 additional disks, one for metadata and for cache, per cluster node
  # for CDM version 9.2.2 and later.
  metadata_disk = {
    device     = "/dev/sdb"
    size       = 132
    type       = "gp3"
    throughput = 125
  }
  cache_disk = {
    device     = "/dev/sdc"
    size       = 206
    type       = "gp3"
    throughput = 125
  }
  cluster_disks = concat(
    local.split_disk ? [local.metadata_disk, local.cache_disk] : [],
    [for v in range(var.cluster_disk_count) : {
      device     = "/dev/sd${substr(local.split_disk ? "defghi" : "bcdefghi", v, 1)}"
      size       = var.cluster_disk_size
      type       = var.cluster_disk_type
      throughput = local.ebs_throughput
    }]
  )
}

data "aws_subnet" "rubrik_cloud_cluster" {
  id = var.aws_subnet_id
}

data "aws_vpc" "rubrik_cloud_cluster" {
  id = data.aws_subnet.rubrik_cloud_cluster.vpc_id
}

data "aws_ami_ids" "rubrik_cloud_cluster" {
  owners = var.aws_ami_owners

  filter {
    name   = "name"
    values = var.aws_ami_filter
  }
}

##############################
# SSH KEY PAIR FOR INSTANCES #
##############################

# Create RSA key of size 4096 bits
resource "tls_private_key" "cc-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Store private key in AWS Secrets Manager
resource "aws_secretsmanager_secret" "cces-private-key" {
  name                    = "${var.cluster_name}-private-key"
  recovery_window_in_days = var.private_key_recovery_window_in_days

  tags = var.aws_tags
}

resource "aws_secretsmanager_secret_version" "cces-private-key-value" {
  secret_id     = aws_secretsmanager_secret.cces-private-key.id
  secret_string = tls_private_key.cc-key.private_key_pem
}

# Create SSH Key
module "aws_key_pair" {
  source          = "terraform-aws-modules/key-pair/aws"
  version         = "~> 2.0.0"

  key_name        = var.aws_key_pair_name == "" ? "${var.cluster_name}.key-pair" : var.aws_key_pair_name
  public_key      = tls_private_key.cc-key.public_key_openssh

  tags = var.aws_tags
}

######################################################################
# Create, then configure, the Security Groups for the Rubrik Cluster #
######################################################################
module "rubrik_nodes_sg" {
  source = "terraform-aws-modules/security-group/aws"

  use_name_prefix = true
  name            = var.aws_vpc_cloud_cluster_nodes_sg_name == "" ? "${var.cluster_name}.sg" : var.aws_vpc_cloud_cluster_nodes_sg_name
  description     = "Allow hosts to talk to Rubrik Cloud Cluster and Cluster to talk to itself"
  vpc_id          = data.aws_subnet.rubrik_cloud_cluster.vpc_id
  tags = var.aws_tags
}

module "rubrik_nodes_sg_rules" {
  source                          = "./modules/rubrik_nodes_sg"
  sg_id                           = module.rubrik_nodes_sg.security_group_id
  rubrik_hosts_sg_id              = module.rubrik_hosts_sg.security_group_id
  cloud_cluster_nodes_admin_cidr  = var.cloud_cluster_nodes_admin_cidr 
  tags = merge(
    { name = "${var.cluster_name}:sg-rule" },
    var.aws_tags
  )
  depends_on = [
    module.rubrik_hosts_sg
  ]
}

module "rubrik_hosts_sg" {
  source = "terraform-aws-modules/security-group/aws"

  use_name_prefix = true
  name            = var.aws_vpc_cloud_cluster_hosts_sg_name == "" ? "${var.cluster_name}.sg" : var.aws_vpc_cloud_cluster_hosts_sg_name
  description     = "Allow Rubrik Cloud Cluster to talk to hosts, and hosts with this security group can talk to cluster"
  vpc_id          = data.aws_subnet.rubrik_cloud_cluster.vpc_id
  tags = var.aws_tags
}

module "rubrik_hosts_sg_rules" {
  source = "./modules/rubrik_hosts_sg"

  sg_id              = module.rubrik_hosts_sg.security_group_id
  rubrik_nodes_sg_id = module.rubrik_nodes_sg.security_group_id
  tags = merge(
    { Name = "${var.cluster_name}:sg-rule" },
    var.aws_tags
  )
  depends_on = [
    module.rubrik_nodes_sg
  ]
}

##############################
# Create IAM Role and Policy #
##############################
module "iam_role" {
  source = "./modules/iam_role"

  bucket_arn            = aws_s3_bucket.cces-s3-bucket.arn
  role_name             = var.aws_cloud_cluster_iam_role_name == "" ? "${var.cluster_name}.role" : var.aws_cloud_cluster_iam_role_name
  role_policy_name      = var.aws_cloud_cluster_iam_role_policy_name == "" ? "${var.cluster_name}.role-policy" : var.aws_cloud_cluster_iam_role_policy_name
  instance_profile_name = var.aws_cloud_cluster_ec2_instance_profile_name == "" ? "${var.cluster_name}.instance-profile" : var.aws_cloud_cluster_ec2_instance_profile_name
  enableImmutability    = var.enableImmutability
}

########################################
# S3 VPC Endpoint for Cloud Cluster ES #
########################################

module "s3_vpc_endpoint" {
  count  = var.create_s3_vpc_endpoint ? 1 : 0
  source = "./modules/s3_vpc_endpoint"

  vpc_id          = data.aws_subnet.rubrik_cloud_cluster.vpc_id
  route_table_ids = var.s3_vpc_endpoint_route_table_ids

  tags = merge(
    { Name = "${var.cluster_name}:ep" },
    var.aws_tags
  )
}

###########################
# Create S3 Bucket in AWS #
###########################

resource "aws_s3_bucket" "cces-s3-bucket" {
  bucket              = var.s3_bucket_name == "" ? "${var.cluster_name}.bucket-do-not-delete" : var.s3_bucket_name
  force_destroy       = var.s3_bucket_force_destroy
  object_lock_enabled = var.enableImmutability
  tags                = var.aws_tags
}

resource "aws_s3_bucket_versioning" "cces-s3-bucket-versioning" {
  count   = local.enableImmutability
  bucket  = aws_s3_bucket.cces-s3-bucket.id
  versioning_configuration {
    status = "Enabled"
  }

}

resource "aws_s3_bucket_public_access_block" "cces-s3-bucket-public-access" {
  bucket = aws_s3_bucket.cces-s3-bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cces-s3-bucket-encryption" {
  bucket = var.s3_bucket_name == "" ? "${var.cluster_name}.bucket-do-not-delete" : var.s3_bucket_name

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
    bucket_key_enabled  = true
  }
}

###############################
# Create EC2 Instances in AWS #
###############################

module "cluster_nodes" {
  source = "./modules/rubrik_aws_instances"

  node_names    = local.cluster_node_names
  node_config   = local.cluster_node_config
  disks         = local.cluster_disks
}

######################################
# Bootstrap the Rubrik Cloud Cluster #
######################################

resource "time_sleep" "wait_for_nodes_to_boot" {
  create_duration = "${var.node_boot_wait}s"

  depends_on = [module.cluster_nodes]
}

resource "polaris_cdm_bootstrap_cces_aws" "bootstrap_cces_aws" {
  cluster_name           = var.cluster_name
  cluster_nodes          = zipmap(local.cluster_node_names, local.cluster_node_ips)
  admin_email            = var.admin_email
  admin_password         = var.admin_password
  management_gateway     = cidrhost(data.aws_subnet.rubrik_cloud_cluster.cidr_block, 1)
  management_subnet_mask = cidrnetmask(data.aws_subnet.rubrik_cloud_cluster.cidr_block)
  dns_search_domain      = var.dns_search_domain
  dns_name_servers       = var.dns_name_servers
  ntp_server1_name       = var.ntp_server1_name
  ntp_server2_name       = var.ntp_server2_name
  bucket_name            = var.s3_bucket_name == "" ? "${var.cluster_name}.bucket-do-not-delete" : var.s3_bucket_name
  enable_immutability    = var.enableImmutability
  timeout                = var.timeout
  depends_on             = [time_sleep.wait_for_nodes_to_boot]
}

##############################################
# Register the Rubrik Cloud Cluster with RSC #
###########################k##################

resource "polaris_cdm_registration" "cces_aws_registration" {
  count                   = var.register_cluster_with_rsc ? 1 : 0
  admin_password          = var.admin_password
  cluster_name            = var.cluster_name
  cluster_node_ip_address = local.cluster_node_ips[0]
  depends_on              = [polaris_cdm_bootstrap_cces_aws.bootstrap_cces_aws]
}
