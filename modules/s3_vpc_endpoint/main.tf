data "aws_region" "current" {}

resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.s3"
  vpc_endpoint_type = "Gateway"

  tags = var.tags
}

data "aws_vpc_endpoint" "this" {
  vpc_id       = var.vpc_id
  id           = aws_vpc_endpoint.s3_endpoint.id
  depends_on = [
    aws_vpc_endpoint.s3_endpoint
  ]
}