data "aws_ami" "cces_ami" {
  filter {
    name   = "image-id"
    values = [local.ami_id]
  }
}

locals {
  # Regular expression parsing the version number from the CCES AMI name.
  version_regex = "^rubrik-mp-cc-(\\d+)-(\\d+)-(\\d+).+$"

  # Extract the major, minor and maintenance version numbers from the CCES AMI
  # name.
  major_minor_maint = regex(local.version_regex, data.aws_ami.cces_ami.name)
  major_version     = parseint(local.major_minor_maint[0], 10)
  minor_version     = parseint(local.major_minor_maint[1], 10)
  maint_version     = parseint(local.major_minor_maint[2], 10)

  # Determine if the split disk feature is enabled based on the major, minor and
  # maintenance version numbers.
  split_disk = local.major_version < 9 || (local.major_version == 9 && local.minor_version < 2) || (local.major_version == 9 && local.minor_version == 2 && local.maint_version < 2) ? false : true
}
