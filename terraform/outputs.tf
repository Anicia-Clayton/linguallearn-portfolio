output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ip" {
  description = "NAT Gateway public IP"
  value       = aws_eip.nat.public_ip
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "rds_secret_arn" {
  description = "ARN of RDS credentials secret"
  value       = aws_secretsmanager_secret.rds_credentials.arn
}

# S3 video storage Outputs
output "video_bucket_name" {
  description = "S3 bucket name for videos"
  value       = aws_s3_bucket.videos.id
}

output "data_lake_bucket_name" {
  description = "S3 bucket name for data lake"
  value       = aws_s3_bucket.data_lake.id
}

# CloudFront Outputs
output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.video_cdn.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.video_cdn.id
}

output "cloudfront_url" {
  description = "Full CloudFront URL"
  value       = "https://${aws_cloudfront_distribution.video_cdn.domain_name}"
}

output "cloudfront_origin_access_control_id" {
  description = "CloudFront Origin Access Control ID"
  value       = aws_cloudfront_origin_access_control.video_oac.id
}
