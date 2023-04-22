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
    type = map(string)
    default = {  }
}

variable "enableImmutability" {
  type = bool
}