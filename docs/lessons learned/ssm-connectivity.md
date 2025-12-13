# Lessons Learned: EC2 SSM Connectivity Issues

**Project:** LinguaLearn AI 
**Date:** November 13, 2025  
**Environment:** AWS EC2 in Private Subnet  
**Status:** Resolved

---

## Executive Summary

Unable to connect to EC2 instances via AWS Systems Manager (SSM) Session Manager. Root cause identified as missing IAM permissions and lack of VPC endpoints for private subnet connectivity. Issues resolved by adding required IAM policies and implementing VPC endpoints.

---

## Challenge 1: Missing IAM Permissions for SSM

### Issue
EC2 instances were not appearing in Systems Manager Fleet Manager, preventing SSM Session Manager connections.

### Root Cause
IAM role attached to EC2 instances lacked the required SSM permissions. The role only included:
- SecretsManagerReadWrite
- CloudWatchAgentServerPolicy

But was missing the essential SSM policy.

### Diagnostic Steps Taken

**Checked if SSM agent was reporting in:**
```cmd
aws ssm describe-instance-information --filters Key=InstanceIds,Values=i-INSTANCE-ID --output text
```
Result: No output (empty) - confirmed instance not registered with SSM

**Verified IAM role was attached:**
```cmd
aws ec2 describe-instances --instance-ids i-INSTANCE-ID --query Reservations[0].Instances[0].IamInstanceProfile --output text
```
Result: IAM profile present

**Listed attached policies:**
```cmd
aws iam list-attached-role-policies --role-name ROLE-NAME --output text
```
Result: Missing AmazonSSMManagedInstanceCore policy

### Solution
Added the required IAM policy to the EC2 role in Terraform:

```hcl
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
```

Applied changes:
```cmd
terraform apply
```

### Outcome
After applying the Terraform changes and waiting 5-10 minutes, instances appeared in Fleet Manager and SSM connections were successful.

---

## Challenge 2: Private Subnet Network Connectivity

### Issue
Even with correct IAM permissions, SSM connectivity requires network access to AWS Systems Manager endpoints. EC2 instances in private subnets without internet access cannot reach SSM.

### Root Cause
Instances were deployed in private subnets without:
- NAT Gateway for internet connectivity, OR
- VPC Endpoints for direct AWS service access

### Solution
Implemented VPC Endpoints for Systems Manager services to enable secure, private connectivity without internet exposure:

```hcl
# SSM Endpoint
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}

# SSM Messages Endpoint
resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}

# EC2 Messages Endpoint
resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}
```

### Outcome
Instances in private subnets could now communicate with SSM endpoints without requiring internet access, maintaining security best practices.

---

## Key Takeaways

1. **IAM Permissions are Critical**: The `AmazonSSMManagedInstanceCore` policy is mandatory for SSM connectivity. Always verify IAM permissions first when troubleshooting SSM issues.

2. **Private Subnets Require Network Path**: Private subnet instances need either NAT Gateway or VPC endpoints to reach AWS services. VPC endpoints are preferred for security and cost efficiency.

3. **Diagnostic Commands Matter**: Using AWS CLI commands to verify configuration is faster than relying solely on console checks.

4. **Wait Time**: After applying IAM or network changes, allow 5-10 minutes for the SSM agent to register with AWS Systems Manager.

5. **Windows/WSL Consideration**: When using Windows with WSL for Terraform, be aware of line ending differences (CRLF vs LF) in shell scripts, though this didn't affect our specific issue.

---

## Prevention Checklist

For future EC2 deployments with SSM, ensure:

- [ ] IAM role includes `AmazonSSMManagedInstanceCore` policy
- [ ] VPC endpoints configured for private subnets (ssm, ssmmessages, ec2messages)
- [ ] Security groups allow HTTPS (443) outbound for VPC endpoints
- [ ] SSM agent is installed (pre-installed on Amazon Linux 2, Ubuntu 20.04+)
- [ ] Verify instance appears in Fleet Manager after 5-10 minutes

---

## References

- [AWS Systems Manager Prerequisites](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-prerequisites.html)
- [VPC Endpoints for Systems Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-create-vpc.html)
- [AmazonSSMManagedInstanceCore Policy](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonSSMManagedInstanceCore.html)
