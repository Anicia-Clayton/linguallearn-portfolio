# LinguaLearn AI - Production ML Infrastructure Platform

Cloud-native ML platform demonstrating end-to-end infrastructure deployment, security architecture, and operational excellence for AI-powered applications.

**Tech Stack:** AWS (VPC, EC2, RDS, Lambda, S3, CloudFront, ALB), Terraform, Python, FastAPI, PostgreSQL

**Live Documentation:** https://anicia-clayton.github.io/linguallearn-portfolio/

---

## About This Project

**Purpose:** Portfolio project demonstrating production-ready ML infrastructure, security architecture, and operational best practices.

**Why this project:** As someone who has studied 12 languages and tutors students, I built this to solve a real problem: traditional flashcard apps don't capture how humans actually learn languages. This authentic use case drives architectural decisions and demonstrates practical problem-solving.

**Technical Focus:** While the application domain is language learning, the primary demonstration is **MLOps and cloud infrastructure engineering** - deployment automation, security architecture, monitoring strategies, and operational best practices for ML systems.

**Current Progress:** Phase 4 of 6.

Infrastructure, API layer, and multi-modal tracking are live.

Currently implementing ML integration.

Next phases: monitoring and CI/CD automation.

---

## Infrastructure & Architecture Highlights

### Production-Ready Cloud Architecture

**Multi-tier infrastructure** with complete infrastructure-as-code implementation:

- **Network Security:** VPC isolation with private/public subnets across 2 Availability Zones, security groups with least-privilege access
- **High Availability:** Multi-AZ RDS deployment with automated failover, Application Load Balancer with health checks
- **Compute Layer:** EC2 for API services, serverless Lambda for event-driven processing and ML inference
- **Data Storage:** PostgreSQL RDS (12+ tables, complex relational queries), S3 data lake, CloudFront CDN for media delivery
- **Security:** Zero-trust model with IAM RBAC, Secrets Manager for credentials, encryption at rest (AES-256) and in transit (TLS 1.2+)

### Infrastructure as Code

**Complete Terraform configuration** demonstrating modular, maintainable infrastructure:

- Automated provisioning of entire AWS stack (20+ resources)
- Modular design enabling AWS → Azure portability
- Version-controlled infrastructure with reproducible deployments
- Environment separation (dev/staging/prod) ready

### ML Deployment Architecture

**Serverless ML inference design** optimized for cost and scalability:

- Lambda functions for ML model inference (80% cost savings vs always-on EC2)
- Event-driven architecture with S3 triggers for automated processing
- Model deployment pipeline supporting multiple algorithms (forgetting curve prediction, churn detection)
- Scalable inference handling variable load patterns

### API & Application Layer

**Production FastAPI deployment** with comprehensive design:

- RESTful endpoints for user management, content CRUD, ML predictions
- Database connection pooling and query optimization
- Health checks, structured logging, error handling
- Designed for horizontal scaling and zero-downtime deployments

### Security & Compliance

**Enterprise security architecture** following AWS best practices:

- IAM role-based access control (RBAC) with least-privilege principle
- Secrets Manager for credential management (database, API keys)
- Network isolation with private subnets for data tier
- Encryption at rest and in transit across all data stores
- Security audit logging with CloudWatch

### Documentation & Operational Excellence

**Comprehensive technical documentation**:

- **Solution Architecture Document (SAD):** Complete system design and architecture
- **8 Architecture Decision Records (ADRs):** Key technical decisions with rationale
  - RDS vs DynamoDB for data storage
  - Lambda for ML inference cost optimization
  - ALB vs API Gateway trade-offs
  - Secrets Manager credential strategy
  - SSL certificate domain management
  - Lambda ML layer architecture
  - Multi-modal data tracking approach
  - ASL video delivery implementation
- **Operational Runbook:** Production procedures with 5 incident response scenarios
- **Troubleshooting Guide:** Common issues and resolutions
- **Lessons Learned:** Detailed problem-solving documentation
  - SSM connectivity
  - Git workflows
  - Lambda optimization

---

## Technical Challenges & Patterns

This project tackles common production challenges with patterns applicable beyond language learning:

### Multi-Modal Data Handling

Different content types require different strategies. Text goes to PostgreSQL for queries. Video goes to S3 + CloudFront for delivery. Lambda processes media on-demand.

**Cross-Industry Applications:** Patient records (healthcare), loan applications (finance), course materials (education) all combine text, images, audio, and video requiring similar storage and delivery patterns.

### Data Bootstrapping & Organic Growth

When external data sources aren't available, how do you launch? Provide curated seed data to get started, then let the system grow through user contributions. Includes quality validation to maintain data integrity as it scales.

**Cross-Industry Applications:** Telemedicine platforms (providers before patients), investment platforms (market data before traders), learning management systems (courses before students) all face the "cold start" problem of needing data to attract users.

### Variable Workload Cost Optimization

Prediction requests are intermittent—sometimes zero, sometimes hundreds per hour. Serverless Lambda scales automatically and only charges for actual usage. Saves 80% compared to always-on servers ($20/month vs $100/month).

**Cross-Industry Applications:** Patient portals (spikes during flu season, enrollment periods), trading platforms (market hours vs overnight), student systems (registration periods, exam days) all have unpredictable usage requiring flexible, cost-efficient scaling.


### Security & Compliance Architecture

Zero-trust security model: encryption at rest (AES-256) and in transit (TLS 1.2+), IAM role-based access control, Secrets Manager for credentials, CloudWatch for audit logging, network isolation with private subnets.

**Cross-Industry Applications:** HIPAA-compliant patient data (healthcare), PCI-DSS payment processing (finance), FERPA-protected student records (education) all require encryption, access controls, audit trails, and regulatory compliance frameworks.

### High Availability & Disaster Recovery

Multi-AZ database deployment with automatic failover, load-balanced application servers (no single point of failure), automated backups. Designed for 99.9% uptime.

**Cross-Industry Applications:** Electronic health records (24/7 patient care), trading platforms (market hours uptime), exam systems (critical deadline reliability) cannot tolerate downtime during critical operations.

### Operational Stability & Change Control

Infrastructure as Code (Terraform) means all changes are reviewed and version-controlled. Comprehensive documentation (8 ADRs, operational runbooks) supports audits and handoffs. Planned CI/CD includes automated testing and rollback procedures.

**Cross-Industry Applications:** Hospital systems (validated changes, rollback capability), financial platforms (tested deployments, instant rollback), university systems (approval processes, stable releases) prioritize reliability over speed in regulated environments.

### Dialect & Variation Support

Supporting regional variations (Dominican Spanish vs Castilian, Taiwan Mandarin vs Mainland) requires flexible data modeling and content organization. PostgreSQL handles this with relational structure.

**Cross-Industry Applications:** Medical terminology variations (US vs UK healthcare systems), financial regulations by jurisdiction (state-specific compliance), curriculum standards by region (state education requirements) all require flexible data models to handle localized content while maintaining system consistency.

---

## Project Structure

```
linguallearn-portfolio/                 # Project root
|
├── README.md                           # This file
├── package.json                        # Node.js dependencies
├── package-lock.json                   # Locked dependency versions
├── tailwind.config.js                  # Tailwind CSS configuration
├── postcss.config.js                   # PostCSS configuration
├── .gitignore                          # Git ignore rules
├── .gitattributes                      # Global line-ending policy
├── .editorconfig                       # For consistent editor settings
├── requirements.txt                    # Python dependencies
├── curl-format.txt                     # Curl Command Format
|
├── docs/                               # Comprehensive documentation
│   ├── SAD.md                          # Solution Architecture Document (portfolio site)
│   ├── RUNBOOK.md                      # Operations guide (portfolio site)
│   ├── ADRs.md                         # Architecture Decision Records (1-6 are on portfolio site)
│   ├── Project_Tracker.xlsx            # Complete Project Tracker
│   ├── TROUBLESHOOTING.md              # Quick reference guide
│   └── lessons-learned/                # Detailed troubleshooting stories
│       ├── ssm-connectivity.md
│       ├── git-nested-repo.md
│       ├── lambda-ml-layer-optimization.md
│
├── public/                             # Public assets
│   └── index.html                      # HTML entry point
│
├── src/                                # React application source
│   ├── App.jsx                         # Main React component (portfolio site)
│   ├── index.js                        # React entry point
│   └── index.css                       # Global styles with Tailwind directives
|
├── terraform/                          # Infrastructure as Code
│   ├── main.tf                         # Main Terraform configuration
│   ├── variables.tf                    # Terraform variables
│   ├── outputs.tf                      # Terraform outputs
│   ├── vpc.tf                          # VPC configuration
│   ├── ec2.tf                          # EC2 instances
│   ├── rds.tf                          # RDS PostgreSQL
│   ├── s3.tf                           # S3 buckets (data + video)
│   ├── cloudfront.tf                   # CloudFront CDN for videos
│   ├── lambda.tf                       # Lambda functions (ML + API)
│   ├── alb.tf                          # Application Load Balancer
│   └── security_groups.tf              # Security group rules
│   └── ssm_endpoints.tf                # SSM Endpoints
│   └── user_data.sh                    # Infrastructure Script
│   └── secrets.tf                      # Secrets Manager
│   └── route53.tf                      # DNS Records
│   └── certificate.tf                  # SSL Certificate
│   └── cloudwatch.tf                   # CloudWatch Logs
│   └── s3.tf                           # S3 Buckets: Data Lake & Video Storage
│   └── cloudfront.tf                   # CloudFront for Content Delivery
│
├── api/                                # Backend API
│   ├── app.py                          # Flask/FastAPI application
│   ├── models/                         # ML models
│   │   ├── forgetting_curve.py         # Forgetting curve prediction model
│   │   └── requirements-ml.txt         # Python dependencies
│   ├── routes/                         # API routes
│   │   ├── users.py                    # User management endpoints
│   │   ├── vocabulary.py               # Vocabulary CRUD endpoints
│   │   ├── practice.py                 # Practice activity tracking
│   │   ├── asl_vocabulary.py           # ASL vocabulary CRUD endpoints
│   │   └── predictions.py              # ML prediction endpoints
│
├── tests/                              # Test scripts
│   ├── test_api.sh                     # Comprehensive API Testing
│   ├── test_practice_api.py            # Comprehensive Practice API Testing
│   ├── test_asl_api.py                 # Comprehensive ASL API Testing
│   ├── requirements-test.txt           # Python dependencies
│
├── scripts/                            # Operational scripts
│   ├── download_upload_asl_videos.sh   # Download ASL demo videos & Upload to S3 bucket
│   ├── train_model.py                  # Train Forgetting Curve Model
|
├── lambda/                             # Lambda functions
│   ├── video_processor/                # ASL video processor
│   │   ├── handler.py                  # Serverless, Event-Driven video processing
|
└── node_modules/                       # Node.js dependencies (gitignored)
```

---

## Project Tracker

Comprehensive development management with automated progress tracking.

**Location:** `docs/Project_Tracker.xlsx`

**Current Metrics:**

- Phase 1 (Infrastructure): 100%
- Phase 2 (API & Compute): 100%
- Phase 3 (Multi-Modal Activities): 100%
- Phase 4 (ML Integration): ~90%
- Phase 5 (Monitoring): 0%
- Phase 6 (CI/CD): 0%

**Features:**

- 6-phase breakdown with granular task management
- Auto-calculated completion percentages
- Color-coded status indicators (Complete, In Progress, Blocked)
- Real-time task counts and blocker tracking
- Full project timeline and change log

---

## Language Learning Features

Supporting 12 languages with authentic practice tracking:

- **Languages:** Spanish, Portuguese, Swahili, Romanian, Mandarin, Hausa, Akan Twi, Tagalog, Egyptian Arabic, French, ASL, Haitian Creole
- **Dialect Support:** Regional variations (Dominican Spanish, Taiwan Mandarin)
- **Practice Types:** Vocabulary, journaling, conversations, media notes (music, shows, books)
- **ML Predictions:** Forgetting curve (when you'll forget words), churn detection (engagement prediction)
- **ASL Support:** Video-based learning with S3 + CloudFront delivery

### ASL Video Content

**Current Status:** Demo content for proof-of-concept development. Videos are technically accurate but are for demonstration purposes only.

**Future Plans:** Partnering with universities for officially licensed ASL curriculum content. This will ensure accessibility standards, cultural authenticity, and proper attribution to ASL educators.

---

## Links

- **Live Portfolio:** https://anicia-clayton.github.io/linguallearn-portfolio/
- **GitHub Repository:** https://github.com/Anicia-Clayton/linguallearn-portfolio
- **Documentation:** Solution Architecture Document, ADRs, and operational runbooks available in portfolio

---

## License

This project is for portfolio demonstration purposes.

**Built by Anicia Clayton** - Cloud Data Engineer exploring MLOps and production ML infrastructure.
