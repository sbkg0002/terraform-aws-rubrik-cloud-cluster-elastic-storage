locals {
  iam_policy = var.enableImmutability == false ? (
    jsonencode ({
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": [
                  "s3:AbortMultipartUpload",
                  "s3:DeleteObject*",
                  "s3:GetObject*",
                  "s3:ListMultipartUploadParts",
                  "s3:PutObject*"
              ],
              "Resource": "${var.bucket_arn}/*"
          },
          {
              "Effect": "Allow",
              "Action": [
                  "s3:GetBucket*",
                  "s3:ListBucket*"
          ],
              "Resource": "${var.bucket_arn}"
          }
      ]
    })
  ) : (
    jsonencode ({
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": [
                  "s3:AbortMultipartUpload",
                  "s3:DeleteObject*",
                  "s3:GetObject*",
                  "s3:ListMultipartUploadParts",
                  "s3:PutObject*"
              ],
              "Resource": "${var.bucket_arn}/*"
          },
          {
              "Effect": "Allow",
              "Action": [
                  "s3:GetBucket*",
                  "s3:ListBucket*",
                  "s3:GetBucketObjectLockConfiguration",
                  "s3:GetObjectLegalHold",
                  "s3:GetObjectRetention",
                  "s3:PutBucketObjectLockConfiguration",
                  "s3:PutObjectLegalHold",
                  "s3:PutObjectRetention"
          ],
              "Resource": "${var.bucket_arn}"
          }
      ]
    })
  ) 
}

resource "aws_iam_role" "rubrik_ec2_s3" {
  name = var.role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "rubrik_ec2_s3_policy" {
  name   = var.role_policy_name
  role   = aws_iam_role.rubrik_ec2_s3.name
  policy = local.iam_policy
}

resource "aws_iam_instance_profile" "rubrik_ec2_s3_profile" {
  name  = var.instance_profile_name
  role  = aws_iam_role.rubrik_ec2_s3.name

  tags = var.tags
}

data "aws_iam_instance_profile" "rubrik_ec2_s3_profile" {
  name       = var.instance_profile_name
  depends_on = [aws_iam_instance_profile.rubrik_ec2_s3_profile]
}

output "aws_iam_instance_profile" {
    value = data.aws_iam_instance_profile.rubrik_ec2_s3_profile
}