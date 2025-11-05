variable "aws_region" {
    description = "AWS region"
    type        = string
    default     = "us-east-1"
  }

  variable "project_name" {
    description = "Project name"
    type        = string
    default     = "linguallearn"
  }

  variable "environment" {
    description = "Environment (dev/staging/prod)"
    type        = string
    default     = "dev"
  }

  variable "vpc_cidr" {
    description = "VPC CIDR block"
    type        = string
    default     = "10.0.0.0/16"
  }