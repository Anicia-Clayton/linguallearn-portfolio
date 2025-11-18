# DNS Record: api.yourdomain.com -> ALB
resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.api_subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# Output the full API URL
output "api_url" {
  description = "Full API URL"
  value       = "https://${var.api_subdomain}.${var.domain_name}"
}
