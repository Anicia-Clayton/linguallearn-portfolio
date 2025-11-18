# ACM Certificate for API subdomain
resource "aws_acm_certificate" "api" {
  domain_name       = "${var.api_subdomain}.${var.domain_name}"
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.domain_name}" # Wildcard for flexibility
  ]

  tags = {
    Name        = "${var.project_name}-cert-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Automatically create DNS validation records
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.api.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# Wait for certificate validation
resource "aws_acm_certificate_validation" "api" {
  certificate_arn         = aws_acm_certificate.api.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "15m" # Wait up to 15 minutes for validation
  }
}

# Data source to reference existing Route 53 zone
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# Outputs
output "certificate_arn" {
  description = "ARN of the SSL certificate"
  value       = aws_acm_certificate.api.arn
}

output "certificate_status" {
  description = "Status of certificate validation"
  value       = aws_acm_certificate.api.status
}

output "api_domain" {
  description = "Full API domain name"
  value       = "${var.api_subdomain}.${var.domain_name}"
}
