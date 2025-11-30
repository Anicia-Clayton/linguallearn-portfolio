# Data Lake Bucket for logs, models, etc.
resource "aws_s3_bucket" "data_lake" {
  bucket = "${var.project_name}-data-lake-${var.environment}-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "${var.project_name}-data-lake-${var.environment}"
    Purpose     = "Data Lake"
  }
}

resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Video Storage Bucket for ASL content
resource "aws_s3_bucket" "video_storage" {
  bucket = "${var.project_name}-videos-${var.environment}-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "${var.project_name}-videos-${var.environment}"
    Purpose     = "ASL Video Storage"
  }
}

resource "aws_s3_bucket_cors_configuration" "video_storage" {
  bucket = aws_s3_bucket.video_storage.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Random suffix for bucket names
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 bucket policy for CloudFront
resource "aws_s3_bucket_policy" "video_storage" {
  bucket = aws_s3_bucket.video_storage.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontAccess"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.video_storage.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.video_cdn.arn
          }
        }
      }
    ]
  })
}
