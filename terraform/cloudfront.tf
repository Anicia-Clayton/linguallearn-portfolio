# Origin Access Control for S3
resource "aws_cloudfront_origin_access_control" "video_oac" {
  name                              = "${var.project_name}-video-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "video_cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "LinguaLearn ASL Video CDN"
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.video_storage.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.video_storage.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.video_oac.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.video_storage.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400    # 1 day
    max_ttl                = 31536000 # 1 year
    compress               = true
  }

  price_class = "PriceClass_100"  # US, Canada, Europe

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "${var.project_name}-video-cdn-${var.environment}"
  }
}
