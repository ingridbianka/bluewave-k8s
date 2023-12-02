
locals {
  num_zones          = var.region == "us-west-1" ? 2 : 3
  base_name_template = "${var.subdomain}-${var.project}"
  name_template      = var.sys_level == "prod" ? local.base_name_template : "${var.sys_level}${local.base_name_template}"
  subdomain_prefix   = replace(substr(var.subdomain, 0, 11), "\\-$", "") //replace - at end of string
  common_tags = {
    sys_level = var.sys_level
    subdomain = var.sys_level == "prod" ? var.subdomain : "${var.sys_level}${var.subdomain}"
    Project   = var.sys_level == "prod" ? var.subdomain : "${var.subdomain}-${var.sys_level}"
  }

  s3_static  = "${local.name_template}-static"
  s3_reports = "${local.name_template}-reports"
}



# Static

resource aws_s3_bucket_policy s3-static-bucket {
  bucket = aws_s3_bucket.s3-static-bucket.bucket
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "PublicReadGetObject"
        Effect = "Allow"
        Principal = "*"
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.s3-static-bucket.arn}/*"
      }
    ]
  })
  depends_on = [
    aws_s3_bucket_acl.s3-static-bucket
    ]
}


resource aws_s3_bucket s3-static-bucket {
  bucket = local.s3_static
  # acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://*", "https://*"]
    max_age_seconds = 3000
  }



  tags = merge(
    {
      Name : local.s3_static
    },
    local.common_tags
  )
}

resource "aws_s3_bucket_ownership_controls" "s3-static-bucket" {
  bucket = aws_s3_bucket.s3-static-bucket.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_public_access_block" "s3-static-bucket" {
  bucket = aws_s3_bucket.s3-static-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "s3-static-bucket" {
  depends_on = [
    aws_s3_bucket_ownership_controls.s3-static-bucket,
    aws_s3_bucket_public_access_block.s3-static-bucket,
  ]

  bucket = aws_s3_bucket.s3-static-bucket.id
  acl    = "public-read"
}

# Reports



# resource aws_s3_bucket_policy s3-reports-bucket {
#   bucket = aws_s3_bucket.s3-reports-bucket.bucket
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid = ""
#         Effect = "Allow"
#         Principal = {
#           AWS = "*"
#         }
#         Action = "s3:*"
#         Resource = "*"
#         Condition = {
#           StringNotEquals = {
#             "aws:SourceVpc": "${module.vpc.vpc_id}"
#           }
#         }
#       }
#     ]
#   })
# }

resource aws_s3_bucket s3-reports-bucket {
  bucket = local.s3_reports

  lifecycle_rule {
    id      = "Send Reports to Glacier after 90d, delete after 7y"
    enabled = true
    prefix  = "media/reports/"

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 2555
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = merge(
    {
      Name : local.s3_reports
    },
    local.common_tags,
  )
}