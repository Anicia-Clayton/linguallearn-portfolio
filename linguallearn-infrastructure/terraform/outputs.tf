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

output "rds_endpoint" {
    description = "RDS instance endpoint"
    value       = aws_db_instance.main.endpoint
    sensitive   = true
  }

  output "rds_secret_arn" {
    description = "ARN of RDS credentials secret"
    value       = aws_secretsmanager_secret.rds_credentials.arn
  }