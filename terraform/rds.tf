# RDS Subnet Group
  resource "aws_db_subnet_group" "main" {
    name       = "${var.project_name}-db-subnet-group-${var.environment}"
    subnet_ids = aws_subnet.private[*].id

    tags = {
      Name = "${var.project_name}-db-subnet-group-${var.environment}"
    }
  }

  # RDS PostgreSQL Instance
  resource "aws_db_instance" "main" {
    identifier     = "${var.project_name}-db-${var.environment}"
    engine         = "postgres"
    engine_version = "14"
    instance_class = var.db_instance_class

    allocated_storage     = var.db_allocated_storage
    max_allocated_storage = 100  # Enable storage autoscaling

    db_name  = "linguallearn"
    username = "postgres"
    password = random_password.rds_password.result

    db_subnet_group_name   = aws_db_subnet_group.main.name
    vpc_security_group_ids = [aws_security_group.rds.id]

    # High Availability
    multi_az = true

    # Backup Configuration
    backup_retention_period = 7
    backup_window           = "03:00-04:00"
    maintenance_window      = "mon:04:00-mon:05:00"

    # Encryption
    storage_encrypted = true

    # Logging
    enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

    # Performance Insights (optional, costs extra)
    # performance_insights_enabled = true

    # Deletion Protection (disable for dev, enable for prod)
    deletion_protection = false
    skip_final_snapshot = true  # For dev only

    tags = {
      Name = "${var.project_name}-rds-${var.environment}"
    }
  }