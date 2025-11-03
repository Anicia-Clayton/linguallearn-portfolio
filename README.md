# LinguaLearn AI - Portfolio Project

Cloud-native ML application for multilingual learning with multi-modal practice tracking and personalized tutor assistance.

**Tech Stack:** AWS (VPC, EC2, RDS PostgreSQL, Lambda, S3, CloudFront, ALB), Terraform, Python, React, AnkiDeck API

**Live Documentation:** https://YOUR-USERNAME.github.io/linguallearn-portfolio  

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

**Current Phase:** Infrastructure & API development (Phase 2 of 6)

---

## Project Structure

```
linguallearn-portfolio/                 # Project root
├── README.md                           # This file
├── package.json                        # Node.js dependencies
├── package-lock.json                   # Locked dependency versions
├── tailwind.config.js                  # Tailwind CSS configuration
├── postcss.config.js                   # PostCSS configuration
├── .gitignore                          # Git ignore rules
│
├── public/                             # Public assets
│   └── index.html                      # HTML entry point
│
├── src/                                # React application source
│   ├── App.jsx                         # Main React component (portfolio site)
│   ├── index.js                        # React entry point
│   └── index.css                       # Global styles with Tailwind directives
└── node_modules/                       # Node.js dependencies (gitignored)
