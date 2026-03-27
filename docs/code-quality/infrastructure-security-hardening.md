# Infrastructure Security Hardening

This document describes the security practices applied to LinguaLearn AI's AWS infrastructure, including lessons learned from a security review.

## Overview

The infrastructure follows AWS security best practices:
- Least-privilege IAM policies
- Function-specific Lambda roles
- S3 public access blocks
- No unnecessary network exposure
- Secrets management via AWS Secrets Manager

## Architecture Security

```
┌─────────────────────────────────────────────────────────────┐
│                         VPC                                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   Public Subnets                      │   │
│  │  ┌─────────┐    ┌─────────────────────────────────┐ │   │
│  │  │   ALB   │───▶│ Security Group: HTTPS only (443)│ │   │
│  │  └────┬────┘    └─────────────────────────────────┘ │   │
│  └───────┼───────────────────────────────────────────────┘   │
│          │                                                   │
│  ┌───────┼───────────────────────────────────────────────┐   │
│  │       │            Private Subnets                     │   │
│  │  ┌────▼────┐    ┌─────────────────────────────────┐   │   │
│  │  │   EC2   │───▶│ Security Group: ALB only (8000) │   │   │
│  │  │   API   │    │ NO SSH (port 22)                │   │   │
│  │  └────┬────┘    └─────────────────────────────────┘   │   │
│  │       │                                                │   │
│  │  ┌────▼────┐    ┌──────────────────┐                  │   │
│  │  │   RDS   │───▶│ SG: EC2 only     │                  │   │
│  │  └─────────┘    └──────────────────┘                  │   │
│  └───────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## IAM Security

### Least-Privilege Secrets Access

**Before (problematic):**
```hcl
resource "aws_iam_role_policy_attachment" "ec2_secrets_manager" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}
```

This grants access to **all** secrets in the account.

**After (scoped):**
```hcl
resource "aws_iam_role_policy" "ec2_secrets_manager" {
  name = "linguallearn-ec2-secrets-dev"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      Resource = ["arn:aws:secretsmanager:us-east-1:*:secret:linguallearn-*"]
    }]
  })
}
```

Now the role can only access secrets prefixed with `linguallearn-`.

### Separated Lambda Roles

Each Lambda function has its own IAM role with only the permissions it needs:

| Lambda | Permissions |
|--------|-------------|
| Video Processor | S3 video bucket (read/write), CloudWatch Logs |
| ML Inference | S3 models path (read), CloudWatch Logs, CloudWatch Metrics |

**Why separate roles?**
- Limits blast radius if a function is compromised
- Makes permissions auditable per-function
- Follows principle of least privilege

```hcl
resource "aws_iam_role" "lambda_video_processor" {
  name = "linguallearn-lambda-video-processor-dev"
  # ...
}

resource "aws_iam_role_policy" "lambda_video_processor" {
  policy = jsonencode({
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = ["${aws_s3_bucket.video_storage.arn}/*"]
      }
      # Only video bucket, not data lake
    ]
  })
}
```

## S3 Security

### Public Access Blocks

All buckets have public access blocks enabled:

```hcl
resource "aws_s3_bucket_public_access_block" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

| Setting | Effect |
|---------|--------|
| `block_public_acls` | Rejects PUT requests with public ACLs |
| `block_public_policy` | Rejects bucket policies that grant public access |
| `ignore_public_acls` | Ignores existing public ACLs |
| `restrict_public_buckets` | Restricts access to bucket owner only |

This is defense in depth—even if someone adds a public policy, it won't take effect.

### Encryption

Both buckets use server-side encryption:

```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

## Network Security

### No SSH Access

**Before (problematic):**
```hcl
ingress {
  description = "SSH"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

**After:**
SSH rule removed entirely. Shell access is via SSM Session Manager.

**Why SSM is better:**
| Aspect | SSH | SSM Session Manager |
|--------|-----|---------------------|
| Inbound ports | Requires port 22 open | No inbound ports needed |
| Authentication | Key management | IAM-based |
| Logging | Manual setup | Automatic CloudWatch/S3 |
| Network exposure | Internet-facing | Private via AWS API |

### Accessing the Instance

```bash
# Start a session
aws ssm start-session --target i-0123456789abcdef0

# Run a command without a session
aws ssm send-command \
  --instance-ids i-0123456789abcdef0 \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["uptime"]'
```

### EC2 Instance Connect Alternative

For emergency SSH access if SSM fails:

```bash
# Temporarily open SSH to your IP only
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxx \
  --protocol tcp \
  --port 22 \
  --cidr $(curl -s ifconfig.me)/32

# After access, remove the rule
aws ec2 revoke-security-group-ingress ...
```

This is documented but discouraged for normal operations.

## Secrets Management

Database credentials are stored in AWS Secrets Manager:

```hcl
resource "aws_secretsmanager_secret" "rds_credentials" {
  name = "linguallearn-rds-credentials-dev"
}
```

**Benefits:**
- Automatic rotation (configurable)
- Audit trail via CloudTrail
- No credentials in code or environment variables
- Versioning for rollback

**Retrieval:**
```python
client = boto3.client('secretsmanager')
response = client.get_secret_value(SecretId='linguallearn-rds-credentials-dev')
credentials = json.loads(response['SecretString'])
```

## VPC Flow Logs

Network traffic is logged to CloudWatch:

```hcl
resource "aws_flow_log" "main" {
  vpc_id          = aws_vpc.main.id
  traffic_type    = "ALL"
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
}
```

**Use cases:**
- Security incident investigation
- Detecting unexpected traffic patterns
- Compliance requirements

**Query example:**
```
fields @timestamp, srcAddr, dstAddr, dstPort, action
| filter action = "REJECT"
| sort @timestamp desc
| limit 100
```

## Lessons Learned

### Issue: Overly Broad IAM Policies

**Symptom:** EC2 role could access all secrets in the account.

**Root Cause:** Using AWS managed policies (like `SecretsManagerReadWrite`) without scoping.

**Fix:** Created inline policies with resource constraints using naming patterns.

**Prevention:** Never use `*` in Resource for production. Always scope to specific ARNs or patterns.

### Issue: Shared Lambda Role

**Symptom:** Video processor Lambda had permissions to read ML models and write metrics.

**Root Cause:** Single IAM role shared across all Lambda functions for convenience.

**Fix:** Created function-specific roles with only required permissions.

**Prevention:** Start with separate roles from the beginning. Merging is easier than splitting.

### Issue: Unnecessary Network Exposure

**Symptom:** SSH port open to internet even though SSM Session Manager was available.

**Root Cause:** SSH rule was a leftover from initial setup/debugging.

**Fix:** Removed SSH rule, verified SSM access works.

**Prevention:** Use SSM from the start. Document emergency SSH procedures separately.

## Security Checklist

For new infrastructure or audits:

**IAM:**
- [ ] No use of `*` in Resource (except CloudWatch Logs)
- [ ] Function-specific roles for Lambda
- [ ] Service roles use specific ARN patterns
- [ ] No AWS managed policies for production secrets/data access

**S3:**
- [ ] Public access blocks on all buckets
- [ ] Server-side encryption enabled
- [ ] Bucket policies don't grant public access
- [ ] Logging enabled for sensitive buckets

**Network:**
- [ ] No SSH rules (or scoped to specific IPs)
- [ ] RDS not publicly accessible
- [ ] Security groups follow least-privilege
- [ ] VPC Flow Logs enabled

**Secrets:**
- [ ] Credentials in Secrets Manager (not env vars)
- [ ] Rotation configured (for production)
- [ ] Access scoped to specific secrets

## References

- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [AWS Security Hub Standards](https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html)
- [S3 Block Public Access](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html)
- [AWS Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
