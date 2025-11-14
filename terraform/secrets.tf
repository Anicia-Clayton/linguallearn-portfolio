# Generate random password for RDS
  resource "random_password" "rds_password" {
    length  = 32
    special = true
  }

  # Store RDS credentials in Secrets Manager
  resource "aws_secretsmanager_secret" "rds_credentials" {
    name        = "${var.project_name}-rds-credentials-${var.environment}"
    description = "RDS PostgreSQL credentials"

    tags = {
      Name = "${var.project_name}-rds-secret-${var.environment}"
    }
  }

  resource "aws_secretsmanager_secret_version" "rds_credentials" {
    secret_id = aws_secretsmanager_secret.rds_credentials.id
    secret_string = jsonencode({
      username = "postgres"
      password = random_password.rds_password.result
      engine   = "postgres"
      host     = aws_db_instance.main.address
      port     = aws_db_instance.main.port
      dbname   = "linguallearn"
    })
  }

  # Enable automatic rotation (optional for now, can enable later)
  # resource "aws_secretsmanager_secret_rotation" "rds" {
  #   secret_id           = aws_secretsmanager_secret.rds_credentials.id
  #   rotation_lambda_arn = aws_lambda_function.secrets_rotation.arn
  #   rotation_rules {
  #     automatically_after_days = 90
  #   }
  # }