# LinguaLearn AI - Portfolio Project

Cloud-native ML application for multilingual learning with multi-modal practice tracking and personalized tutor assistance.

**Tech Stack:** AWS (VPC, EC2, RDS PostgreSQL, Lambda, S3, CloudFront, ALB), Terraform, Python, React, AnkiDeck API

**Live Documentation:** https://anicia-clayton.github.io/linguallearn-portfolio/

---

## About This Project

**Project Goal:** A portfolio project demonstrating cloud architecture, ML engineering, API integration, multimedia handling, and production-ready practices.

I've studied 12 languages (Spanish, Portuguese, Swahili, Romanian, Mandarin, Hausa, Akan Twi, Tagalog, Egyptian Arabic, French, ASL, Haitian Creole) and currently maintain 5 while tutoring students. This project solves a personal problem: traditional flashcard apps don't capture how humans actually learn languages through journaling, media consumption, conversations, and daily practice.

### Core Features

- **Multi-Modal Practice Tracking:** Log journaling entries, music/show notes, book summaries, and conversations - not just flashcards
- **Language Assignment System:** Assign target languages to specific people or daily tasks (e.g., "always think in Spanish when texting Mom")
- **ASL Support:** Video-based learning for American Sign Language with S3 + CloudFront CDN delivery
- **Dialect-Specific Content:** Dominican Spanish, Taiwan Mandarin, and regional language variations
- **ML Predictions:** Forgetting curve prediction and churn detection using serverless Lambda functions
- **Tutor Feedback Integration:** Tutors review learner activities and provide personalized guidance
- **AnkiDeck API Integration:** Pull authentic vocabulary data from community-vetted language decks
- **12 Languages Supported:** Spanish, Portuguese, Swahili, Romanian, Mandarin, Hausa, Akan Twi, Tagalog, Egyptian Arabic, French, ASL, Haitian Creole

### Architecture Highlights

- **Multi-tier cloud architecture** with VPC isolation, private/public subnets across 2 Availability Zones
- **Serverless ML inference** using Lambda functions for cost optimization (80% cost savings vs always-on EC2)
- **PostgreSQL RDS** with Multi-AZ deployment for high availability and complex relational queries (12+ tables)
- **S3 + CloudFront CDN** for ASL video storage and global content delivery
- **External API integration** (AnkiDeck) for vocabulary data ingestion
- **Zero-trust security model** with IAM RBAC, encryption at rest (AES-256) and in transit (TLS 1.2+)
- **Infrastructure-as-Code** using Terraform with modular design for AWS → Azure portability
- **Comprehensive documentation:** Solution Architecture Document (SAD), 6 Architecture Decision Records (ADRs), operational runbook with 5 incident scenarios

### Project Tracker

Comprehensive Excel-based tracker managing all 6 development phases with automated progress monitoring.

**Location:** docs/PROJECT_TRACKER.xlsx

**Features:**
- Auto-calculated completion percentages
- Color-coded status indicators
- Real-time task counts and blocker tracking
- Full project timeline and change log

**Current Phase:** Infrastructure & API development (Phase 2 of 6)

---

## Project Documentation

This project includes comprehensive documentation organized by purpose:

### Core Documentation (in /docs/)

- Solution Architecture Document (SAD) - Complete system architecture and design
- Architecture Decision Records (ADRs) - Key technical decisions with rationale

  - ADR-001: RDS vs DynamoDB for data storage
  - ADR-002: Lambda for ML inference vs always-on EC2
  - ADR-003: ALB vs API Gateway
  - ADR-004: Secrets Manager for credential management
  - ADR-005: ASL video support implementation
  - ADR-006: Multi-modal practice tracking approach

- Operational Runbook - Production procedures and incident response

### Development Resources

- Troubleshooting Guide - Quick fixes for common development issues

  - Configuration errors
  - AWS CLI issues
  - Git and version control problems
  - Development environment setup


- Lessons Learned - Detailed problem-solving documentation

  - SSM Connectivity Issues
  - Git Sync Issues (nested repo)

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
|
├── docs/                               # Comprehensive documentation
│   ├── SAD.md                          # Solution Architecture Document
│   ├── RUNBOOK.md                      # Operations guide
│   ├── ADR.md                          # Architecture Decision Record
│   ├── Project_Tracker.xlsx            # Complete Project Tracker
│   ├── TROUBLESHOOTING.md              # Quick reference guide
│   └── lessons-learned/                # Detailed troubleshooting stories
│       ├── ssm-connectivity.md
│       ├── git-nested-repo.md
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
│   └── secrets.tf                      # Secrets Manager
│   └── route53.tf                      # DNS Records
│   └── certificate.tf                  # SSL Certificate
│   └── cloudwatch.tf                   # CloudWatch Logs
│
├── api/                                # Backend API
│   ├── app.py                          # Flask/FastAPI application
│   ├── models/                         # ML models
│   │   ├── forgetting_curve.py         # Forgetting curve prediction model
│   │   └── churn_detection.py          # Churn detection model
│   ├── routes/                         # API routes
│   │   ├── users.py                    # User management endpoints
│   │   ├── vocabulary.py               # Vocabulary CRUD endpoints
│   │   ├── practice.py                 # Practice activity tracking
│   │   └── predictions.py              # ML prediction endpoints
│   └── utils/                          # Utility functions
│       ├── ankideck_client.py          # AnkiDeck API integration
│       └── db_connection.py            # Database connection pooling
│
├── tests/                              # Test scripts
│   ├── test_api.sh                     # Comprehensive API Testing
|
└── node_modules/                       # Node.js dependencies (gitignored)
