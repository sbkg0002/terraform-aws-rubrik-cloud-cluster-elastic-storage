variable "bucket_arn" {
  type = string
}

variable "role_name" {
  type = string
}

variable "role_policy_name" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enableImmutability" {
  type = bool
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
