# Week 1 - Day 1: setup

✅ AWS account configured with billing alarms
✅ IAM admin user created with MFA
✅ AWS CLI and Terraform installed and working
✅ Terraform project structure initialized

# Week 1 - Day 2: infrastrutucre

✅ VPC created with CIDR 10.0.0.0/16
✅ 2 public subnets + 2 private subnets across 2 AZs
✅ Internet Gateway and NAT Gateway deployed
✅ Route tables configured



# Week 1 - Day 3

✅ 4 security groups created (ALB, EC2, RDS, Lambda)
✅ Zero-trust model: each component has minimal required access
✅ Security groups properly reference each other

  # Security Group Configuration
  
  ## Zero-Trust Network Model
  Each resource has minimal required access. No direct internet access except ALB.
  
  ## Security Groups
  
  ### ALB Security Group (linguallearn-alb-sg-dev)
  **Purpose:** Accept HTTPS/HTTP traffic from internet, forward to EC2
  
  **Ingress:**
  - Port 443 (HTTPS) from 0.0.0.0/0 - Public web traffic
  - Port 80 (HTTP) from 0.0.0.0/0 - Redirect to HTTPS
  
  **Egress:**
  - Port 8000 to EC2 Security Group - Forward to API server
  
  ### EC2 Security Group (linguallearn-ec2-sg-dev)
  **Purpose:** Run API server, connect to RDS
  
  **Ingress:**
  - Port 8000 from ALB Security Group ONLY - API traffic
  - Port 22 from 0.0.0.0/0 - SSH (TEMPORARY - will lock down in Week 2)
  
  **Egress:**
  - All traffic - Internet access for updates, RDS connections
  
  ### RDS Security Group (linguallearn-rds-sg-dev)
  **Purpose:** Database access from EC2 only
  
  **Ingress:**
  - Port 5432 from EC2 Security Group ONLY - PostgreSQL
  
  **Egress:**
  - All traffic - Response traffic
  
  ### Lambda Security Group (linguallearn-lambda-sg-dev)
  **Purpose:** Lambda functions for ML inference
  
  **Ingress:**
  - None (Lambda doesn't accept incoming connections)
  
  **Egress:**
  - All traffic - S3, RDS, external APIs
  
  ## Security Testing Results
  
  ✅ RDS not publicly accessible (verified)
  ✅ RDS connection from local machine fails (expected)
  ✅ Security groups properly reference each other
  ✅ No unnecessary 0.0.0.0/0 ingress rules (except ALB ports 80/443)
  
  ## TODO for Week 2
  - [ ] Lock down SSH: Change EC2 SG from 0.0.0.0/0 to specific IP
  - [ ] OR: Remove SSH entirely, use AWS Session Manager instead

# Week 1 - Day 4

