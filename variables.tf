# Instance/Node Settings

variable "aws_region" {
  description = "The region to deploy Rubrik Cloud Cluster nodes."
  type        = string
}

variable "aws_instance_imdsv2" {
  description = "Enable support for IMDSv2 instances. Only supported with CCES v8.1.3 or CCES v9.0 and higher."
  type        = bool
  default     = false
}

variable "aws_instance_type" {
  description = "The type of instance to use as Rubrik Cloud Cluster nodes. CC-ES requires m5.4xlarge."
  type        = string
  default     = "m5.4xlarge"
}

variable "aws_disable_api_termination" {
  description = "If true, enables EC2 Instance Termination Protection on the Rubrik Cloud Cluster nodes."
  type        = bool
  default     = true
}

variable "aws_tags" {
  description = "Tags to add to the AWS resources that this Terraform script creates, including the Rubrik cluster nodes."
  type        = map(string)
  default     = {}
}

variable "number_of_nodes" {
  description = "The total number of nodes in Rubrik Cloud Cluster."
  type        = number
  default     = 3
}

variable "aws_ami_owners" {
  description = "AWS marketplace account(s) that owns the Rubrik Cloud Cluster AMIs. Use use 679593333241 for AWS Commercial and 345084742485 for AWS GovCloud."
  type        = set(string)
  default     = ["679593333241"]
}

variable "aws_ami_filter" {
  description = "Cloud Cluster AWS AMI name pattern(s) to search for. Use 'rubrik-mp-cc-<X>*' without the single quotes. Where <X> is the major version of CDM. Ex. 'rubrik-mp-cc-7*'"
  type        = set(string)
}

variable "aws_image_id" {
  description = "AWS Image ID to deploy. Set to 'latest' or leave blank to deploy the latest version from the marketplace."
  type        = string
  default     = "latest"
}

variable "aws_key_pair_name" {
  description = "Name for the AWS SSH Key-Pair being created or the existing AWS SSH Key-Pair being used."
  type        = string
  default     = ""
}

variable "private_key_recovery_window_in_days" {
  description = "Recovery window in days to recover script generated ssh private key."
  type        = number
  default     = 30
}

# Network Settings

variable "aws_vpc_cloud_cluster_nodes_sg_name" {
  description = "The name of the security group to create for Rubrik Cloud Cluster to use."
  type        = string
  default     = "Rubrik Cloud Cluster Nodes"
}

variable "cloud_cluster_nodes_admin_cidr" {
  description = "The CIDR range for the systems used to administer the Cloud Cluster via SSH and HTTPS."
  type        = string
  default     = "0.0.0.0/0"
}

variable "aws_vpc_cloud_cluster_hosts_sg_name" {
  description = "The name of the security group to create for Rubrik Cloud Cluster to communicate with EC2 instances."
  type        = string
  default     = "Rubrik Cloud Cluster Hosts"
}

variable "aws_cloud_cluster_nodes_sg_ids" {
  description = "Additional security groups to add to Rubrik cluster nodes."
  type        = list(string)
  default     = []
}

variable "aws_subnet_id" {
  description = "The VPC Subnet ID to launch Rubrik Cloud Cluster in."
  type        = string
}

# Storage Settings

variable "cluster_disk_type" {
  description = "Disk type for the data disk: gp2 or gp3. Note, gp3 is only supported from version 8.1.1 for Cloud Cluster ES."
  type        = string
  default     = "gp3"
}

variable "cluster_disk_size" {
  description = "The size (in GB) of each data disk on each node. Cloud Cluster ES only requires 1 512 GB disk per node."
  type        = number
  default     = 512
}

variable "cluster_disk_count" {
  description = "The number of disks for each node in the cluster. Set to 1 to use with S3 storage for Cloud Cluster ES."
  type        = number
  default     = 1
}

# Cloud Cluster ES Settings

variable "aws_cloud_cluster_iam_role_name" {
  description = "AWS IAM Role name for Cloud Cluster ES. If blank a name will be auto generated."
  type        = string
  default     = ""
}

variable "aws_cloud_cluster_iam_role_policy_name" {
  description = "AWS IAM Role policy name for Cloud Cluster ES. If blank a name will be auto generated."
  type        = string
  default     = ""
}

variable "aws_cloud_cluster_ec2_instance_profile_name" {
  description = "AWS EC2 Instance Profile name that links the IAM Role to Cloud Cluster ES. If blank a name will be auto generated."
  type        = string
  default     = ""
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket to use with Cloud Cluster ES data storage. If blank a name will be auto generated."
  type        = string
  default     = ""
}

variable "enableImmutability" {
  description = "Enables object lock and versioning on the S3 bucket. Sets the object lock flag during bootstrap. Not supported on CDM v8.0.1 and earlier."
  type        = bool
  default     = true
}

variable "s3_bucket_force_destroy" {
  description = "A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error."
  type        = bool
  default     = false
}

variable "create_s3_vpc_endpoint" {
  description = "Determines whether an S3 VPC endpoint is created."
  type        = bool
  default     = true
}

variable "s3_vpc_endpoint_route_table_ids" {
  description = "Route table IDs if S3 VPC endpoint is created."
  type        = list(string)
  default     = []
}

# Bootstrap Settings

variable "cluster_name" {
  description = "Unique name to assign to the Rubrik Cloud Cluster. This will also be used to populate the EC2 instance name tag. For example, rubrik-cloud-cluster-1, rubrik-cloud-cluster-2 etc."
  default     = "rubrik-cloud-cluster"
}

variable "admin_email" {
  description = "The Rubrik Cloud Cluster sends messages for the admin account to this email address."
  type        = string
}

variable "admin_password" {
  description = "Password for the Rubrik Cloud Cluster admin account."
  type        = string
  sensitive   = true
  default     = "ChangeMe"
}

variable "dns_search_domain" {
  type        = list(any)
  description = "List of search domains that the DNS Service will use to resolve hostnames that are not fully qualified."
  default     = []
}

variable "dns_name_servers" {
  type        = list(any)
  description = "List of the IPv4 addresses of the DNS servers."
  default     = ["169.254.169.253"]
}

variable "ntp_server1_name" {
  description = "The FQDN or IPv4 addresses of network time protocol (NTP) server #1."
  type        = string
  default     = "8.8.8.8"
}

variable "ntp_server1_key_id" {
  description = "The ID number of the symmetric key used with NTP server #1. (Typically this is 0)"
  type        = number
  default     = 0
}

variable "ntp_server1_key" {
  description = "Symmetric key material for NTP server #1."
  type        = string
  sensitive   = true
  default     = ""
}

variable "ntp_server1_key_type" {
  description = "Symmetric key type for NTP server #1."
  type        = string
  sensitive   = true
  default     = ""
}

variable "ntp_server2_name" {
  description = "The FQDN or IPv4 addresses of network time protocol (NTP) server #2."
  type        = string
  default     = "8.8.4.4"
}

variable "ntp_server2_key_id" {
  description = "The ID number of the symmetric key used with NTP server #2. (Typically this is 0)"
  type        = number
  default     = 0
}

variable "ntp_server2_key" {
  description = "Symmetric key material for NTP server #2."
  type        = string
  sensitive   = true
  default     = ""
}

variable "ntp_server2_key_type" {
  description = "Symmetric key type for NTP server #2."
  type        = string
  sensitive   = true
  default     = ""
}

variable "timeout" {
  description = "The number of seconds to wait to establish a connection the Rubrik cluster before returning a timeout error."
  type        = string
  default     = "4m"
}

variable "node_boot_wait" {
  description = "Number of seconds to wait for CCES nodes to boot before attempting to bootstrap them."
  type        = number
  default     = 300
}

variable "register_cluster_with_rsc" {
  description = "Register the Rubrik Cloud Cluster with Rubrik Security Cloud."
  type        = bool
  default     = false
}

variable "role_path" {
  type        = string
  default     = null
  description = "Path to the role."
}

variable "role_permissions_boundary" {
  type        = string
  default     = null
  description = "ARN of the policy that is used to set the permissions boundary for the role."
}
