# VPC Flow Logs
  resource "aws_flow_log" "main" {
    iam_role_arn    = aws_iam_role.vpc_flow_log.arn
    log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
    traffic_type    = "ALL"
    vpc_id          = aws_vpc.main.id

    tags = {
      Name = "${var.project_name}-vpc-flow-log-${var.environment}"
    }
  }

  resource "aws_cloudwatch_log_group" "vpc_flow_log" {
    name              = "/aws/vpc/${var.project_name}-${var.environment}"
    retention_in_days = 30

    tags = {
      Name = "${var.project_name}-vpc-logs-${var.environment}"
    }
  }

  # IAM Role for VPC Flow Logs
  resource "aws_iam_role" "vpc_flow_log" {
    name = "${var.project_name}-vpc-flow-log-role-${var.environment}"

    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "vpc-flow-logs.amazonaws.com"
          }
        }
      ]
    })
  }

  resource "aws_iam_role_policy" "vpc_flow_log" {
    name = "${var.project_name}-vpc-flow-log-policy-${var.environment}"
    role = aws_iam_role.vpc_flow_log.id

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }

  # Log Groups for future services
  resource "aws_cloudwatch_log_group" "api" {
    name              = "/aws/ec2/${var.project_name}-api-${var.environment}"
    retention_in_days = 30

    tags = {
      Name = "${var.project_name}-api-logs-${var.environment}"
    }
  }

  resource "aws_cloudwatch_log_group" "rds" {
    name              = "/aws/rds/${var.project_name}-${var.environment}"
    retention_in_days = 30

    tags = {
      Name = "${var.project_name}-rds-logs-${var.environment}"
    }
  }

  resource "aws_cloudwatch_log_group" "lambda" {
    name              = "/aws/lambda/${var.project_name}-${var.environment}"
    retention_in_days = 30

    tags = {
      Name = "${var.project_name}-lambda-logs-${var.environment}"
    }
  }