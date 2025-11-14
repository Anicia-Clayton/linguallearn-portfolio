# ALB Security Group (will be used in Phase 2)
  resource "aws_security_group" "alb" {
    name        = "${var.project_name}-alb-sg-${var.environment}"
    description = "Security group for Application Load Balancer"
    vpc_id      = aws_vpc.main.id

    ingress {
      description = "HTTPS from anywhere"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
      description = "HTTP from anywhere (redirect to HTTPS)"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      description = "Allow all outbound"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name = "${var.project_name}-alb-sg-${var.environment}"
    }
  }

  # EC2 Security Group
  resource "aws_security_group" "ec2" {
    name        = "${var.project_name}-ec2-sg-${var.environment}"
    description = "Security group for EC2 API server"
    vpc_id      = aws_vpc.main.id

    ingress {
      description     = "API traffic from ALB"
      from_port       = 8000
      to_port         = 8000
      protocol        = "tcp"
      security_groups = [aws_security_group.alb.id]
    }

    ingress {
      description = "SSH from specific IP (optional - add your IP)"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]  # CHANGE THIS to your IP for security
    }

    egress {
      description = "Allow all outbound"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name = "${var.project_name}-ec2-sg-${var.environment}"
    }
  }

  # RDS Security Group
  resource "aws_security_group" "rds" {
    name        = "${var.project_name}-rds-sg-${var.environment}"
    description = "Security group for RDS PostgreSQL"
    vpc_id      = aws_vpc.main.id

    ingress {
      description     = "PostgreSQL from EC2"
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [aws_security_group.ec2.id]
    }

    egress {
      description = "Allow all outbound"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name = "${var.project_name}-rds-sg-${var.environment}"
    }
  }

  # Lambda Security Group (for VPC-enabled Lambdas)
  resource "aws_security_group" "lambda" {
    name        = "${var.project_name}-lambda-sg-${var.environment}"
    description = "Security group for Lambda functions"
    vpc_id      = aws_vpc.main.id

    egress {
      description = "Allow all outbound"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name = "${var.project_name}-lambda-sg-${var.environment}"
    }
  }