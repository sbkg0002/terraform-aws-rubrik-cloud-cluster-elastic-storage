resource "aws_instance" "rubrik_cluster" {
  for_each               = var.node_names
  instance_type          = var.node_config.instance_type
  ami                    = var.node_config.ami_id
  vpc_security_group_ids = var.node_config.sg_ids
  subnet_id              = var.node_config.subnet_id
  key_name               = var.node_config.key_pair_name
  metadata_options {
    http_tokens = var.node_config.http_tokens
  }
  lifecycle {
    ignore_changes = [ami]
  }
  tags = merge({
    Name = each.value },
    var.node_config.tags
  )

  disable_api_termination = var.node_config.disable_api_termination
  iam_instance_profile    = var.node_config.iam_instance_profile
  root_block_device {
    encrypted   = true
    volume_type = var.node_config.root_volume_type
    throughput  = var.node_config.root_volume_throughput
    tags = merge(
      { Name = "${each.value}-sda" },
      var.node_config.tags
    )
  }
  dynamic "ebs_block_device" {
    for_each = var.disks
    content {
      volume_type = ebs_block_device.value.type
      volume_size = ebs_block_device.value.size
      throughput  = ebs_block_device.value.throughput
      tags = merge(
        { Name = "${each.key}-${element(split("/", ebs_block_device.value.device), 2)}" },
        var.node_config.tags
      )
      device_name = ebs_block_device.value.device
      encrypted   = true
    }
  }

}

output "instances" {
  value = aws_instance.rubrik_cluster
}