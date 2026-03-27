# ADR-007: SSL Certificate and Domain Strategy

## Status
Accepted

## Date
2025-11-18

## Context
The LinguaLearn AI API requires secure HTTPS communication for production deployment. We needed to:
1. Select and register a domain name
2. Implement SSL/TLS certificate management
3. Configure DNS routing
4. Ensure automatic certificate renewal
5. Maintain infrastructure as code principles

### Requirements
- Secure HTTPS endpoints for API
- Professional domain for portfolio presentation
- Automated certificate provisioning and renewal
- Cost-effective solution
- Integration with existing AWS infrastructure

### Domain Name Considerations
- **Primary choice unavailable**: `linguallearn.com` was already registered
- **Options evaluated**:
  - `linguallearn.org` - Educational focus, clean URL
  - `lingua-learn.com` - Professional but hyphen adds typing friction
  - `linguallearn.net` - Outdated perception, users default to .com

## Decision
We will implement SSL/TLS security using:

1. **Domain**: `linguallearn.org`
   - Registered via AWS Route 53
   - `.org` TLD aligns with educational/learning purpose
   - Clean URL without hyphens or special characters

2. **SSL Certificate**: AWS Certificate Manager (ACM)
   - Free SSL certificates
   - Automatic renewal
   - Domain: `api.linguallearn.org`
   - Wildcard support: `*.linguallearn.org`

3. **DNS Management**: AWS Route 53
   - Hosted zone for `linguallearn.org`
   - Automatic DNS validation for ACM certificates
   - A record alias pointing to Application Load Balancer

4. **Load Balancer Configuration**:
   - HTTPS listener on port 443 with ACM certificate
   - HTTP listener on port 80 with 301 redirect to HTTPS
   - TLS policy: `ELBSecurityPolicy-TLS13-1-2-2021-06`

## Consequences

### Positive
- ✅ **Free SSL certificates**: ACM provides certificates at no cost
- ✅ **Automatic renewal**: No manual certificate management
- ✅ **Infrastructure as Code**: Entire setup managed via Terraform
- ✅ **Professional presentation**: HTTPS endpoints for portfolio
- ✅ **Security best practices**: Modern TLS 1.3 policy
- ✅ **Integrated AWS ecosystem**: Route 53, ACM, and ALB work seamlessly
- ✅ **Educational alignment**: `.org` TLD matches learning platform purpose
- ✅ **DNS validation automation**: Terraform creates validation records automatically

### Negative
- ❌ **Domain cost**: ~$12/year for domain registration
- ❌ **Route 53 cost**: $0.50/month for hosted zone
- ❌ **DNS propagation delay**: Initial setup requires 15-60 minutes wait
- ❌ **Regional limitation**: ACM certificates are region-specific (us-east-1)
- ❌ **Validation dependency**: ALB creation blocked until certificate validates

### Neutral
- ⚪ **`.org` instead of `.com`**: Different perception but appropriate for use case
- ⚪ **AWS vendor lock-in**: ACM certificates only work with AWS services
- ⚪ **Certificate scope**: Wildcard cert provides flexibility but broader than needed

## Implementation Details

### Terraform Resources Created
```hcl
# certificate.tf
- aws_acm_certificate.api
- aws_route53_record.cert_validation
- aws_acm_certificate_validation.api

# route53.tf
- data.aws_route53_zone.main (references existing zone)
- aws_route53_record.api (A record for api subdomain)

# alb.tf (updated)
- aws_lb_listener.https (certificate_arn updated)
- HTTP listener redirects to HTTPS
```

### Configuration
- **Domain**: `linguallearn.org`
- **API Endpoint**: `https://api.linguallearn.org`
- **Certificate Validation**: DNS (automatic via Route 53)
- **Certificate Scope**: `api.linguallearn.org` + `*.linguallearn.org`
- **TLS Policy**: ELBSecurityPolicy-TLS13-1-2-2021-06
- **HTTP Behavior**: 301 redirect to HTTPS

### Security Groups Updated
- ALB security group: Added ingress rule for port 443 (HTTPS)
- Maintained existing port 80 (HTTP) for redirect functionality

## Alternatives Considered

### 1. Self-Signed Certificates
**Rejected** - Browser warnings, not production-ready, poor portfolio presentation

### 2. Let's Encrypt + Certbot
**Rejected** - Requires manual renewal setup, EC2 installation complexity, not IaC-friendly

### 3. No SSL (HTTP only)
**Rejected** - Insecure, unprofessional for portfolio, doesn't demonstrate production skills

### 4. Different TLD (.io, .dev, .ai)
**Rejected** - More expensive ($25-60/year), .org provides best value and relevance

### 5. External DNS Provider (Cloudflare, Namecheap DNS)
**Rejected** - Adds complexity, breaks AWS integration, manual certificate validation

## Cost Analysis

| Item | Monthly Cost | Annual Cost |
|------|--------------|-------------|
| Domain Registration (.org) | - | $12.00 |
| Route 53 Hosted Zone | $0.50 | $6.00 |
| ACM Certificate | FREE | FREE |
| DNS Queries (first 1M free) | ~$0.00 | ~$0.00 |
| **Total** | **$0.50/month** | **$18.00/year** |

**Note**: This is incremental cost. ALB and other infrastructure costs remain unchanged.

## Validation Criteria
- [x] Domain successfully registered in Route 53
- [x] Hosted zone created automatically
- [x] ACM certificate requested for `api.linguallearn.org`
- [x] DNS validation records created automatically
- [x] Certificate status: ISSUED
- [ ] HTTPS endpoint accessible: `https://api.linguallearn.org/api/health`
- [ ] HTTP redirects to HTTPS (301 status)
- [ ] Browser shows valid certificate (no warnings)
- [ ] Certificate includes wildcard domain

## References
- AWS Certificate Manager Documentation: https://docs.aws.amazon.com/acm/
- Route 53 Documentation: https://docs.aws.amazon.com/route53/
- ALB HTTPS Listener Documentation: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/
- TLS Best Practices: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html

## Related Decisions
- ADR-002: AWS as Cloud Provider (provides ACM, Route 53)
- ADR-003: VPC and Network Architecture (public subnets for ALB)
- ADR-004: Security Model (HTTPS requirement)

## Timeline
- **2025-11-18**: Domain registered, Terraform configuration created
- **Expected validation**: 5-15 minutes after terraform apply
- **Full deployment**: 1-2 hours including DNS propagation

## Lessons for Interview Discussion
This decision demonstrates understanding of:
- Production security requirements (HTTPS/TLS)
- Cost-effective cloud architecture
- Infrastructure as Code practices
- AWS service integration (Route 53, ACM, ALB)
- DNS and certificate validation concepts
- Security best practices (TLS 1.3, automatic renewal)

## Notes
- Certificate is tied to us-east-1 region (where infrastructure is deployed)
- Wildcard certificate (`*.linguallearn.org`) provides flexibility for future subdomains
- DNS validation chosen over email validation for automation compatibility
- Route 53 automatic validation eliminates manual DNS record creation
- 301 redirect ensures all traffic uses HTTPS
