# VPC Endpoints for Systems Manager (SSM) access to EC2 in private subnet

# Security group for VPC endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.project_name}-vpc-endpoints-sg-${var.environment}"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-vpc-endpoints-sg-${var.environment}"
  }
}

# SSM Endpoint
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-ssm-endpoint-${var.environment}"
  }
}

# SSM Messages Endpoint (required for Session Manager)
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-ssmmessages-endpoint-${var.environment}"
  }
}

# EC2 Messages Endpoint (required for Session Manager)
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-ec2messages-endpoint-${var.environment}"
  }
}

# Output the endpoint IDs
output "ssm_vpc_endpoint_id" {
  description = "SSM VPC Endpoint ID"
  value       = aws_vpc_endpoint.ssm.id
}

output "ssmmessages_vpc_endpoint_id" {
  description = "SSM Messages VPC Endpoint ID"
  value       = aws_vpc_endpoint.ssmmessages.id
}

output "ec2messages_vpc_endpoint_id" {
  description = "EC2 Messages VPC Endpoint ID"
  value       = aws_vpc_endpoint.ec2messages.id
}
