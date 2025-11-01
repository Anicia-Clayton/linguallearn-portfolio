import React, { useState } from 'react';
import { FileText, Cpu, Shield, DollarSign, AlertTriangle, Book } from 'lucide-react';

const Section = ({ title, children }) => (
  <div className="mb-6">
    <h3 className="text-2xl font-bold text-gray-900 mb-4">{title}</h3>
    {children}
  </div>
);

const Component = ({ name, description }) => (
  <div className="bg-gray-50 p-4 rounded-lg border-l-4 border-indigo-600">
    <h4 className="font-semibold text-gray-900 mb-2">{name}</h4>
    <p className="text-sm text-gray-700">{description}</p>
  </div>
);

const ADR = ({ number, title, status, context, decision, rationale, consequences }) => (
  <div className="bg-white border-2 border-gray-200 rounded-lg p-6 mb-6">
    <div className="flex items-start justify-between mb-4">
      <h4 className="text-xl font-bold text-gray-900">ADR-{number}: {title}</h4>
      <span className="px-3 py-1 bg-green-100 text-green-800 text-sm font-semibold rounded-full">{status}</span>
    </div>
    
    <div className="space-y-4">
      <div>
        <h5 className="font-semibold text-gray-900 mb-1">Context</h5>
        <p className="text-gray-700 text-sm">{context}</p>
      </div>
      
      <div>
        <h5 className="font-semibold text-gray-900 mb-1">Decision</h5>
        <p className="text-gray-700 text-sm">{decision}</p>
      </div>
      
      <div>
        <h5 className="font-semibold text-gray-900 mb-2">Rationale</h5>
        <ul className="space-y-1">
          {rationale.map((item, idx) => (
            <li key={idx} className="text-gray-700 text-sm">• {item}</li>
          ))}
        </ul>
      </div>
      
      <div>
        <h5 className="font-semibold text-gray-900 mb-2">Consequences</h5>
        <ul className="space-y-1">
          {consequences.map((item, idx) => (
            <li key={idx} className="text-gray-700 text-sm">{item}</li>
          ))}
        </ul>
      </div>
    </div>
  </div>
);

const SecurityControl = ({ title, description }) => (
  <div className="bg-gray-50 p-3 rounded border-l-4 border-red-600">
    <h5 className="font-semibold text-gray-900 text-sm mb-1">{title}</h5>
    <p className="text-sm text-gray-700">{description}</p>
  </div>
);

const CostCard = ({ phase, total, items, note }) => (
  <div className="bg-white border-2 border-gray-200 rounded-lg p-6">
    <h4 className="text-lg font-bold text-gray-900 mb-2">{phase}</h4>
    <div className="text-3xl font-bold text-indigo-600 mb-4">{total}/mo</div>
    <div className="space-y-2">
      {items.map((item, idx) => (
        <div key={idx} className="flex justify-between text-sm">
          <span className="text-gray-700">{item.service}</span>
          <span className="text-gray-900 font-semibold">{item.cost}</span>
        </div>
      ))}
    </div>
    {note && <p className="text-xs text-gray-500 mt-4 italic">{note}</p>}
  </div>
);

const Incident = ({ number, title, symptoms, rootCause, resolution, prevention }) => (
  <div className="bg-white border-2 border-orange-200 rounded-lg p-6 mb-6">
    <h4 className="text-lg font-bold text-gray-900 mb-4">Incident #{number}: {title}</h4>
    
    <div className="space-y-3">
      <div>
        <h5 className="font-semibold text-orange-900 text-sm mb-1">Symptoms</h5>
        <p className="text-sm text-gray-700">{symptoms}</p>
      </div>
      
      <div>
        <h5 className="font-semibold text-orange-900 text-sm mb-1">Root Cause</h5>
        <p className="text-sm text-gray-700">{rootCause}</p>
      </div>
      
      <div>
        <h5 className="font-semibold text-orange-900 text-sm mb-1">Resolution Steps</h5>
        <ol className="space-y-1">
          {resolution.map((step, idx) => (
            <li key={idx} className="text-sm text-gray-700">{idx + 1}. {step}</li>
          ))}
        </ol>
      </div>
      
      <div>
        <h5 className="font-semibold text-orange-900 text-sm mb-1">Prevention</h5>
        <p className="text-sm text-gray-700">{prevention}</p>
      </div>
    </div>
  </div>
);

const OverviewSection = () => (
  <div className="space-y-6">
    <Section title="Problem Statement">
      <p className="text-gray-700 leading-relaxed">
        Language learners struggle to maintain multiple languages simultaneously due to inefficient study schedules 
        and lack of personalized feedback. Tutors spend excessive time manually tracking student progress and 
        planning lessons. Meanwhile, learners abandon their studies due to plateaus they don't see coming.
      </p>
    </Section>

    <Section title="Solution">
      <p className="text-gray-700 leading-relaxed mb-4">
        LinguaLearn AI is a cloud-native ML platform that predicts learner retention curves, detects learning 
        pattern anomalies, and automates personalized lesson recommendations. The system helps learners stay 
        motivated and enables tutors to intervene before students churn.
      </p>
      <div className="bg-indigo-50 border-l-4 border-indigo-600 p-4 rounded">
        <h4 className="font-semibold text-indigo-900 mb-2">Core Features:</h4>
        <ul className="space-y-2 text-gray-700">
          <li>• <strong>Forgetting Curve Prediction:</strong> ML model predicts when vocabulary will be forgotten</li>
          <li>• <strong>Learning Pattern Recognition:</strong> Identifies optimal study times and methods per user</li>
          <li>• <strong>Churn Detection:</strong> Flags at-risk learners 7-14 days before they typically quit</li>
          <li>• <strong>Automated Lesson Planning:</strong> Generates personalized study schedules</li>
          <li>• <strong>Multi-Language Support:</strong> Built for 12+ languages from day one</li>
        </ul>
      </div>
    </Section>

    <Section title="Tech Stack Summary">
      <div className="grid grid-cols-2 gap-4">
        <div className="bg-blue-50 p-4 rounded-lg">
          <h4 className="font-semibold text-blue-900 mb-2">AWS Core (Required)</h4>
          <ul className="text-sm text-gray-700 space-y-1">
            <li>• VPC (Multi-AZ)</li>
            <li>• IAM (RBAC)</li>
            <li>• EC2 (API Server)</li>
            <li>• S3 (Data Lake)</li>
          </ul>
        </div>
        <div className="bg-green-50 p-4 rounded-lg">
          <h4 className="font-semibold text-green-900 mb-2">Add-On Services</h4>
          <ul className="text-sm text-gray-700 space-y-1">
            <li>• RDS PostgreSQL (User/Progress Data)</li>
            <li>• ALB (Load Balancing)</li>
            <li>• CloudWatch (Monitoring)</li>
            <li>• Secrets Manager (Credentials)</li>
          </ul>
        </div>
      </div>
      <div className="mt-4 bg-purple-50 p-4 rounded-lg">
        <h4 className="font-semibold text-purple-900 mb-2">ML & Automation</h4>
        <p className="text-sm text-gray-700">
          Lambda functions for ML inference (prediction API), SageMaker for model training (optional - can train locally), 
          EventBridge for scheduled tasks, Terraform for IaC, GitHub Actions for CI/CD
        </p>
      </div>
    </Section>

    <Section title="Presentation Angle">
      <div className="bg-yellow-50 border-l-4 border-yellow-600 p-4 rounded">
        <h4 className="font-semibold text-yellow-900 mb-2">Your Story Hook:</h4>
        <p className="text-gray-700 italic">
          "I've studied 12 languages in my spare time and currently maintain 5. I also tutor kids regularly. 
          The hardest part isn't learning - it's not forgetting. I built LinguaLearn AI to solve my own problem: 
          predicting when I'm about to lose progress and automating the tedious parts of lesson planning so tutors 
          like me can focus on actual teaching."
        </p>
      </div>
    </Section>
  </div>
);

const SADSection = () => (
  <div className="space-y-6">
    <Section title="Solution Architecture Document (SAD)">
      <div className="bg-gray-50 p-4 rounded-lg mb-4">
        <h4 className="font-semibold text-gray-900 mb-2">Architecture Diagram (High-Level)</h4>
        <div className="bg-white p-6 rounded border-2 border-gray-300 font-mono text-xs overflow-x-auto">
          <pre className="whitespace-pre">{`┌─────────────────────────────────────────────────────────────────┐
│                         PUBLIC INTERNET                          │
└────────────────────────────┬────────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │  Route 53 (DNS) │
                    └────────┬────────┘
                             │
        ┌────────────────────▼────────────────────┐
        │       Application Load Balancer (ALB)   │
        │         (Public Subnet - Multi-AZ)      │
        └────────────────────┬────────────────────┘
                             │
        ┌────────────────────▼────────────────────┐
        │              VPC                        │
        │  ┌──────────────────────────────────┐   │
        │  │   Private Subnet (Multi-AZ)      │   │
        │  │                                  │   │
        │  │  ┌─────────┐      ┌──────────┐  │   │
        │  │  │   EC2   │◄────►│   RDS    │  │   │
        │  │  │  (API)  │      │(PostgreSQL)│ │   │
        │  │  └────┬────┘      └──────────┘  │   │
        │  │       │                          │   │
        │  │       ▼                          │   │
        │  │  ┌─────────┐                    │   │
        │  │  │ Lambda  │ (ML Inference)     │   │
        │  │  └────┬────┘                    │   │
        │  └───────┼──────────────────────────┘   │
        │          │                               │
        │          ▼                               │
        │     ┌────────┐      ┌──────────────┐    │
        │     │   S3   │      │  Secrets     │    │
        │     │ (Data) │      │  Manager     │    │
        │     └────────┘      └──────────────┘    │
        │                                          │
        │     ┌──────────────┐                    │
        │     │ CloudWatch   │ (Logs/Metrics)     │
        │     └──────────────┘                    │
        └──────────────────────────────────────────┘
        ┌──────────────────────────────────────────┐
        │  EventBridge (Scheduled ML Training)     │
        └──────────────────────────────────────────┘`}</pre>
        </div>
      </div>
    </Section>

    <Section title="Component Descriptions">
      <div className="space-y-4">
        <Component 
          name="VPC (Virtual Private Cloud)"
          description="Isolated network with public and private subnets across 2 Availability Zones for high availability. Public subnet hosts ALB, private subnet hosts EC2 API server and RDS database."
        />
        <Component 
          name="Application Load Balancer (ALB)"
          description="Distributes incoming HTTPS traffic across EC2 instances. Handles SSL/TLS termination. Enables horizontal scaling when traffic increases."
        />
        <Component 
          name="EC2 API Server"
          description="Hosts the REST API built with Python (Flask/FastAPI). Handles user authentication, CRUD operations, and orchestrates ML predictions via Lambda."
        />
        <Component 
          name="RDS PostgreSQL"
          description="Relational database storing user profiles, learning progress, vocabulary cards, and historical predictions. Multi-AZ deployment for failover."
        />
        <Component 
          name="Lambda Functions"
          description="Serverless compute for ML inference (forgetting curve predictions, churn detection). Triggered by API requests or EventBridge schedules."
        />
        <Component 
          name="S3 Data Lake"
          description="Stores raw learning session logs, trained ML models, and backup data. Organized with prefixes: /raw-data, /models, /backups."
        />
        <Component 
          name="Secrets Manager"
          description="Secures database credentials, API keys, and encryption keys. Integrated with RDS for automatic rotation."
        />
        <Component 
          name="CloudWatch"
          description="Centralized logging and monitoring. Tracks API latency, error rates, Lambda invocations, and custom ML accuracy metrics."
        />
        <Component 
          name="EventBridge"
          description="Schedules nightly ML model retraining jobs and sends daily prediction batches for all active users."
        />
      </div>
    </Section>

    <Section title="Data Flow">
      <ol className="space-y-3 text-gray-700">
        <li><strong>1. User Login:</strong> Request hits ALB → EC2 validates credentials against RDS → Returns JWT token</li>
        <li><strong>2. Learning Session:</strong> User completes vocabulary practice → EC2 logs session to RDS and S3 → Triggers Lambda for immediate prediction update</li>
        <li><strong>3. Prediction Request:</strong> User requests "What should I study today?" → EC2 calls Lambda with user history → Lambda loads model from S3, generates predictions → Returns personalized study plan</li>
        <li><strong>4. Churn Detection:</strong> EventBridge triggers nightly Lambda job → Analyzes all users' engagement patterns → Flags at-risk users in RDS → Sends alert notifications</li>
        <li><strong>5. Model Retraining:</strong> Weekly EventBridge trigger → Lambda pulls new training data from S3 → Trains updated models → Saves to S3 → Updates model version in RDS</li>
      </ol>
    </Section>

    <Section title="Scalability (10x Traffic)">
      <div className="bg-blue-50 p-4 rounded-lg">
        <h4 className="font-semibold text-blue-900 mb-3">Current: ~100 concurrent users</h4>
        <ul className="space-y-2 text-gray-700">
          <li>• 1x EC2 t3.small</li>
          <li>• RDS db.t3.micro</li>
          <li>• Lambda: minimal concurrent executions</li>
        </ul>
        
        <h4 className="font-semibold text-blue-900 mt-4 mb-3">10x Traffic: ~1,000 concurrent users</h4>
        <ul className="space-y-2 text-gray-700">
          <li>• <strong>EC2:</strong> Auto-scaling group with 3-5 t3.medium instances behind ALB</li>
          <li>• <strong>RDS:</strong> Upgrade to db.t3.small with Read Replicas for analytics queries</li>
          <li>• <strong>Lambda:</strong> Increase concurrency limits (handles this well by design)</li>
          <li>• <strong>S3:</strong> No changes needed (scales infinitely)</li>
          <li>• <strong>Caching:</strong> Add ElastiCache (Redis) for frequently accessed predictions</li>
          <li>• <strong>Cost Impact:</strong> ~$300-500/month (still very affordable)</li>
        </ul>
      </div>
    </Section>
  </div>
);

const ADRSection = () => (
  <div className="space-y-6">
    <Section title="Architecture Decision Records (ADRs)">
      <p className="text-gray-600 mb-6">Key technical decisions with justifications</p>
    </Section>

    <ADR
      number="001"
      title="Use RDS PostgreSQL Instead of DynamoDB"
      status="Accepted"
      context="Need to store user profiles, learning progress with complex relationships (users → languages → vocabulary → sessions)"
      decision="Selected RDS PostgreSQL over DynamoDB"
      rationale={[
        "Complex relational queries needed (JOIN across users, sessions, predictions)",
        "Strong ACID compliance for financial tracking if monetized later",
        "Easier migration to Azure SQL Database (requirement for cloud portability)",
        "Team familiarity with SQL from current role"
      ]}
      consequences={[
        "Pro: Rich query capabilities, better for analytics",
        "Pro: Simpler data modeling for relationships",
        "Con: More expensive than DynamoDB at scale (~$15-25/mo vs $5-10/mo)",
        "Con: Requires vertical scaling (vs DynamoDB's horizontal scaling)"
      ]}
    />

    <ADR
      number="002"
      title="Lambda for ML Inference vs EC2-Hosted Model"
      status="Accepted"
      context="ML predictions needed for forgetting curves and churn detection"
      decision="Use Lambda functions for inference, not embedding models in EC2 API server"
      rationale={[
        "Serverless = pay-per-prediction (cost-efficient for portfolio project)",
        "Auto-scaling built-in (no need to manage infrastructure)",
        "Isolates ML logic from API server (better separation of concerns)",
        "Faster cold starts with lightweight models (sklearn, not deep learning)"
      ]}
      consequences={[
        "Pro: ~80% cost savings during low usage ($5/mo vs $30/mo for dedicated EC2)",
        "Pro: Easy to swap models without redeploying API server",
        "Con: Cold start latency ~1-3 seconds (acceptable for this use case)",
        "Con: 15-minute max execution time (requires batch processing for training)"
      ]}
    />

    <ADR
      number="003"
      title="Use ALB Instead of API Gateway"
      status="Accepted"
      context="Need to expose REST API to frontend clients"
      decision="Application Load Balancer over API Gateway"
      rationale={[
        "Supports WebSocket connections for future real-time features",
        "Better integration with EC2 auto-scaling groups",
        "Lower cost at scale ($20/mo base vs $3.50/million requests)",
        "Direct Azure Application Gateway equivalent (easier migration)"
      ]}
      consequences={[
        "Pro: Unified load balancing for EC2 fleet",
        "Pro: Built-in health checks and failover",
        "Con: More complex initial setup than API Gateway",
        "Con: Overkill for very low traffic (but needed to demonstrate cloud skills)"
      ]}
    />

    <ADR
      number="004"
      title="Secrets Manager Over SSM Parameter Store"
      status="Accepted"
      context="Need secure storage for RDS credentials, API keys"
      decision="AWS Secrets Manager instead of Systems Manager Parameter Store"
      rationale={[
        "Automatic credential rotation for RDS (security best practice)",
        "Built-in versioning for secrets",
        "Better audit logging via CloudWatch",
        "Direct Azure Key Vault equivalent"
      ]}
      consequences={[
        "Pro: Enhanced security with automatic rotation",
        "Pro: Easier compliance demonstration for interviews",
        "Con: Slightly more expensive ($0.40/secret/mo vs $0.05 for SSM)",
        "Con: Total cost: ~$2-3/mo (negligible for this project)"
      ]}
    />
  </div>
);

const SecuritySection = () => (
  <div className="space-y-6">
    <Section title="Security Model">
      <div className="bg-red-50 border-l-4 border-red-600 p-4 rounded mb-6">
        <h4 className="font-semibold text-red-900 mb-2">Core Principle: Zero Trust</h4>
        <p className="text-gray-700">
          Every component must authenticate and authorize. No implicit trust between services.
        </p>
      </div>
    </Section>

    <Section title="Identity & Access Management (IAM)">
      <div className="space-y-3">
        <SecurityControl
          title="Role-Based Access Control (RBAC)"
          description="Separate IAM roles for EC2 (api-server-role), Lambda (ml-inference-role), EventBridge (scheduler-role). Least privilege principle."
        />
        <SecurityControl
          title="No Hardcoded Credentials"
          description="All credentials stored in Secrets Manager. EC2 and Lambda use IAM roles to retrieve secrets dynamically."
        />
        <SecurityControl
          title="Multi-Factor Authentication (MFA)"
          description="Required for all AWS console access during development and deployment."
        />
      </div>
    </Section>

    <Section title="Network Security">
      <div className="space-y-3">
        <SecurityControl
          title="VPC Isolation"
          description="Private subnets have no direct internet access. NAT Gateway for outbound traffic only."
        />
        <SecurityControl
          title="Security Groups (Firewalls)"
          description="ALB: Allow 443 from 0.0.0.0/0. EC2: Allow 8000 from ALB only. RDS: Allow 5432 from EC2 only. Lambda: VPC endpoints for S3/Secrets Manager."
        />
        <SecurityControl
          title="TLS/SSL Everywhere"
          description="ALB terminates HTTPS (TLS 1.2+). Internal traffic between EC2-RDS encrypted in transit. S3 buckets enforce SSL."
        />
      </div>
    </Section>

    <Section title="Data Protection">
      <div className="space-y-3">
        <SecurityControl
          title="Encryption at Rest"
          description="RDS: AES-256 encryption enabled. S3: Server-side encryption (SSE-S3). EBS volumes: Encrypted by default."
        />
        <SecurityControl
          title="Encryption in Transit"
          description="All API calls use HTTPS. RDS connections use SSL. Secrets Manager uses TLS 1.2+."
        />
        <SecurityControl
          title="Data Backup & Recovery"
          description="RDS automated backups (7-day retention). S3 versioning enabled for model artifacts. Point-in-time recovery for RDS."
        />
      </div>
    </Section>

    <Section title="Monitoring & Compliance">
      <div className="space-y-3">
        <SecurityControl
          title="CloudWatch Alarms"
          description="Failed login attempts > 5 in 5 minutes. Unauthorized API calls (403 errors). RDS connection failures."
        />
        <SecurityControl
          title="Audit Logging"
          description="CloudTrail enabled for all AWS API calls. Application logs sent to CloudWatch Logs. RDS query logs enabled for suspicious activity."
        />
        <SecurityControl
          title="Vulnerability Scanning"
          description="AWS Inspector for EC2 vulnerability assessment. Dependabot for Python dependency scanning in GitHub."
        />
      </div>
    </Section>

    <Section title="Interview Talking Points">
      <div className="bg-green-50 p-4 rounded-lg">
        <h4 className="font-semibold text-green-900 mb-3">How do you control access?</h4>
        <p className="text-gray-700 mb-4">
          "I implemented RBAC using IAM roles with least privilege. Each component has exactly the permissions 
          it needs - EC2 can't access Lambda execution roles, Lambda can only read specific S3 prefixes. 
          No service accounts, no hardcoded keys."
        </p>
        
        <h4 className="font-semibold text-green-900 mb-3">Who can do what?</h4>
        <p className="text-gray-700 mb-4">
          "End users authenticate via JWT tokens with 24-hour expiration. Tutors have elevated permissions to 
          view student progress. Admins can retrain models and access audit logs. Everything is logged to CloudWatch."
        </p>
        
        <h4 className="font-semibold text-green-900 mb-3">How is data protected?</h4>
        <p className="text-gray-700">
          "Encryption everywhere: TLS 1.2+ in transit, AES-256 at rest for RDS and S3. Secrets automatically rotate 
          every 90 days. Private subnets have no internet access. I can demonstrate this by showing the security 
          group rules and encryption settings in the Terraform code."
        </p>
      </div>
    </Section>
  </div>
);

const CostSection = () => (
  <div className="space-y-6">
    <Section title="Monthly Cost Breakdown">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <CostCard
          phase="Development (1-3 months)"
          total="$50-150"
          items={[
            { service: "VPC & Networking", cost: "$0 (free tier)" },
            { service: "EC2 t3.small (stopped often)", cost: "$15-30" },
            { service: "RDS db.t3.micro", cost: "$0-15 (free tier 1st year)" },
            { service: "Application Load Balancer", cost: "$20-25" },
            { service: "S3 Storage (< 5GB)", cost: "$1-2" },
            { service: "Lambda (low usage)", cost: "$0-5" },
            { service: "CloudWatch Logs", cost: "$5-10" },
            { service: "Secrets Manager (5 secrets)", cost: "$2-3" },
            { service: "Data Transfer", cost: "$5-10" }
          ]}
        />
        
        <CostCard
          phase="Production (Portfolio Mode)"
          total="$30-60"
          items={[
            { service: "EC2 (stopped when not demoing)", cost: "$5-10" },
            { service: "RDS (minimal usage)", cost: "$15-20" },
            { service: "ALB (always running)", cost: "$20-25" },
            { service: "S3 + Lambda + CloudWatch", cost: "$5-10" },
            { service: "Secrets Manager", cost: "$2-3" }
          ]}
          note="Stop EC2 between interviews to save 70%"
        />
      </div>
    </Section>

    <Section title="10x Traffic Cost Estimate">
      <div className="bg-yellow-50 border-l-4 border-yellow-600 p-4 rounded">
        <h4 className="font-semibold text-yellow-900 mb-3">Scaling from 100 to 1,000 concurrent users</h4>
        <div className="space-y-2 text-gray-700">
          <div className="flex justify-between">
            <span>EC2 Auto-Scaling (3-5x t3.medium instances)</span>
            <span className="font-semibold">$100-150/mo</span>
          </div>
          <div className="flex justify-between">
            <span>RDS db.t3.small + Read Replica</span>
            <span className="font-semibold">$60-80/mo</span>
          </div>
          <div className="flex justify-between">
            <span>Application Load Balancer</span>
            <span className="font-semibold">$30-40/mo</span>
          </div>
          <div className="flex justify-between">
            <span>ElastiCache (Redis - t3.micro)</span>
            <span className="font-semibold">$15-20/mo</span>
          </div>
          <div className="flex justify-between">
            <span>Lambda (10x invocations)</span>
            <span className="font-semibold">$20-30/mo</span>
          </div>
          <div className="flex justify-between">
            <span>S3, CloudWatch, Data Transfer</span>
            <span className="font-semibold">$30-50/mo</span>
          </div>
          <div className="flex justify-between border-t-2 border-yellow-600 pt-2 mt-2">
            <span className="font-bold">Total (10x Traffic)</span>
            <span className="font-bold text-yellow-900">$255-370/mo</span>
          </div>
        </div>
        <p className="text-sm text-gray-600 mt-3">
          Note: Still affordable for a production app serving 1,000 users. Could reduce costs by 30-40% with 
          Reserved Instances or Savings Plans.
        </p>
      </div>
    </Section>

    <Section title="Azure Migration Cost Comparison">
      <div className="bg-blue-50 p-4 rounded-lg">
        <h4 className="font-semibold text-blue-900 mb-3">AWS → Azure Equivalent Costs</h4>
        <div className="space-y-2 text-sm text-gray-700">
          <div className="flex justify-between">
            <span>EC2 t3.small → Azure B2s VM</span>
            <span>~5% cheaper on Azure</span>
          </div>
          <div className="flex justify-between">
            <span>RDS PostgreSQL → Azure Database for PostgreSQL</span>
            <span>Nearly identical (~$15-20/mo)</span>
          </div>
          <div className="flex justify-between">
            <span>ALB → Azure Application Gateway</span>
            <span>~10% more expensive on Azure</span>
          </div>
          <div className="flex justify-between">
            <span>Lambda → Azure Functions</span>
            <span>Same pricing model (pay-per-execution)</span>
          </div>
          <div className="flex justify-between">
            <span>S3 → Azure Blob Storage</span>
            <span>~5-10% cheaper on Azure</span>
          </div>
          <div className="flex justify-between">
            <span>Secrets Manager → Azure Key Vault</span>
            <span>~50% cheaper on Azure ($0.03/10k ops)</span>
          </div>
        </div>
        <p className="text-sm text-gray-600 mt-3 font-semibold">
          Overall: Azure would cost approximately 5-10% less for this architecture at portfolio scale.
        </p>
      </div>
    </Section>

    <Section title="Cost Optimization Strategies">
      <div className="space-y-3">
        <div className="bg-gray-50 p-3 rounded">
          <h5 className="font-semibold text-gray-900">Development Phase</h5>
          <ul className="text-sm text-gray-700 mt-2 space-y-1">
            <li>• Use AWS Free Tier for RDS first 12 months (save $15-20/mo)</li>
            <li>• Stop EC2 instances when not actively developing (save 70%)</li>
            <li>• Use S3 Intelligent-Tiering for automatic cost optimization</li>
            <li>• Set CloudWatch billing alarms at $50, $100 thresholds</li>
          </ul>
        </div>
        
        <div className="bg-gray-50 p-3 rounded">
          <h5 className="font-semibold text-gray-900">Interview/Demo Phase</h5>
          <ul className="text-sm text-gray-700 mt-2 space-y-1">
            <li>• Tear down and rebuild with Terraform in 10 minutes (save 90%)</li>
            <li>• Keep only S3 data + RDS snapshots between demos (~$5/mo)</li>
            <li>• Use Lambda-only architecture (no EC2) for minimal demo needs</li>
          </ul>
        </div>
        
        <div className="bg-gray-50 p-3 rounded">
          <h5 className="font-semibold text-gray-900">Production Scaling</h5>
          <ul className="text-sm text-gray-700 mt-2 space-y-1">
            <li>• Purchase Reserved Instances for EC2/RDS (save 30-40%)</li>
            <li>• Implement ElastiCache to reduce RDS query load</li>
            <li>• Use S3 Lifecycle policies to archive old training data</li>
            <li>• Optimize Lambda memory allocation for cost/performance</li>
          </ul>
        </div>
      </div>
    </Section>
  </div>
);

const RunbookSection = () => (
  <div className="space-y-6">
    <Section title="Operational Runbook">
      <p className="text-gray-600 mb-6">Common incidents, troubleshooting steps, and preventive measures</p>
    </Section>

    <Incident
      number="1"
      title="API Server (EC2) Not Responding - 504 Gateway Timeout"
      symptoms="Users report 504 errors. ALB health checks failing. CloudWatch shows EC2 CPU at 100%."
      rootCause="EC2 instance overwhelmed by traffic spike. No auto-scaling configured yet."
      resolution={[
        "Check CloudWatch metrics: EC2 CPU, Network In/Out, ALB request count",
        "SSH into EC2: 'ssh -i key.pem ec2-user@<private-ip>' (via bastion if needed)",
        "Check application logs: 'sudo journalctl -u api-server -n 100'",
        "Restart API service: 'sudo systemctl restart api-server'",
        "If persists, scale up: Stop instance, change type to t3.medium, restart",
        "Monitor recovery via CloudWatch dashboard"
      ]}
      prevention="Implement EC2 Auto Scaling Group with target tracking on CPU > 70%. Add CloudWatch alarm for sustained high CPU."
    />

    <Incident
      number="2"
      title="RDS Connection Errors - 'Too Many Connections'"
      symptoms="API returns 500 errors. Logs show 'OperationalError: FATAL: remaining connection slots reserved'. CloudWatch shows RDS connections at max."
      rootCause="Connection pool exhausted. Application not closing connections properly or pool size too small."
      resolution={[
        "Check RDS CloudWatch: DatabaseConnections metric (max is based on instance class)",
        "Identify long-running queries: Connect via psql, run 'SELECT * FROM pg_stat_activity WHERE state = active;'",
        "Kill problematic connections: 'SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE pid = <PID>;'",
        "Verify connection pool config in app: max_connections should be < RDS limit",
        "If needed, upgrade RDS instance class for more connection slots"
      ]}
      prevention="Implement connection pooling with pgBouncer. Set max_connections in app config to 80% of RDS limit. Add monitoring for connection count."
    />

    <Incident
      number="3"
      title="Lambda Cold Start Latency - Predictions Taking 5+ Seconds"
      symptoms="Users complain about slow predictions. CloudWatch shows Lambda Init Duration > 3 seconds."
      rootCause="Lambda function cold starting frequently. Model loading from S3 taking too long."
      resolution={[
        "Check CloudWatch Logs for Lambda: Filter by 'REPORT RequestId' to see Init Duration",
        "Verify model size in S3: 'aws s3 ls s3://linguallearn-models/ --recursive --human'",
        "If model > 50MB, consider: (a) reducing model complexity, (b) using provisioned concurrency",
        "Enable Provisioned Concurrency (costs more but eliminates cold starts): 'aws lambda put-provisioned-concurrency-config'",
        "Alternative: Cache model in /tmp for subsequent invocations within same Lambda container"
      ]}
      prevention="Keep models under 10MB (use lightweight sklearn models). Implement model quantization. Use Lambda Provisioned Concurrency for production."
    />

    <Incident
      number="4"
      title="S3 Access Denied Errors - Lambda Can't Read Model Files"
      symptoms="Lambda returns 403 errors. Logs show 'botocore.exceptions.ClientError: Access Denied'. Predictions fail."
      rootCause="Lambda IAM role missing S3 GetObject permissions or bucket policy blocking access."
      resolution={[
        "Check Lambda IAM role: 'aws iam get-role-policy --role-name ml-inference-role --policy-name S3Access'",
        "Verify S3 bucket policy: 'aws s3api get-bucket-policy --bucket linguallearn-models'",
        "Test access from Lambda: Add temporary logging to print IAM role ARN and S3 bucket name",
        "Update IAM policy to include: 's3:GetObject' on 'arn:aws:s3:::linguallearn-models/*'",
        "Check S3 bucket encryption settings - ensure KMS key grants Lambda access if using KMS"
      ]}
      prevention="Use least privilege IAM policies. Test Lambda S3 access in dev environment before deploying. Add CloudWatch alarm for Lambda 403 errors."
    />

    <Incident
      number="5"
      title="Secrets Manager Rotation Broke Database Connection"
      symptoms="API server can't connect to RDS. Logs show authentication failures. Secrets Manager recently rotated password."
      rootCause="Application caching old credentials instead of fetching fresh ones from Secrets Manager."
      resolution={[
        "Verify current secret in Secrets Manager: 'aws secretsmanager get-secret-value --secret-id rds-credentials'",
        "Test RDS connection manually: 'psql -h <rds-endpoint> -U admin -d linguallearn'",
        "Check application code: Ensure secrets are fetched on each connection, not cached at startup",
        "Restart API server to force secret refresh: 'sudo systemctl restart api-server'",
        "If urgent: Temporarily disable rotation, fix app code, then re-enable"
      ]}
      prevention="Update application to fetch secrets dynamically (not at startup). Test rotation in dev environment. Add monitoring for authentication failures."
    />

    <Section title="Useful Commands Reference">
      <div className="bg-gray-50 p-4 rounded-lg">
        <h4 className="font-semibold text-gray-900 mb-3">AWS CLI Quick Reference</h4>
        <div className="font-mono text-xs space-y-2 text-gray-700">
          <div><strong>Check EC2 Status:</strong> aws ec2 describe-instance-status --instance-ids i-xxxxx</div>
          <div><strong>View CloudWatch Logs:</strong> aws logs tail /aws/ec2/api-server --follow</div>
          <div><strong>List Lambda Invocations:</strong> aws lambda list-functions --query Functions[*].[FunctionName]</div>
          <div><strong>Check RDS Status:</strong> aws rds describe-db-instances --db-instance-identifier linguallearn-db</div>
          <div><strong>View S3 Bucket Size:</strong> aws s3 ls s3://linguallearn-models/ --recursive --summarize</div>
          <div><strong>Test Secrets Access:</strong> aws secretsmanager get-secret-value --secret-id rds-credentials</div>
        </div>
      </div>
    </Section>

    <Section title="Monitoring Dashboard Links">
      <div className="bg-blue-50 p-4 rounded-lg">
        <h4 className="font-semibold text-blue-900 mb-3">Key Metrics to Watch</h4>
        <ul className="text-sm text-gray-700 space-y-2">
          <li>• <strong>API Health:</strong> ALB Target Health, Request Count, 4XX/5XX Errors</li>
          <li>• <strong>Compute:</strong> EC2 CPU Utilization, Network Bytes, Disk I/O</li>
          <li>• <strong>Database:</strong> RDS Connections, CPU, Free Storage, Read/Write Latency</li>
          <li>• <strong>Serverless:</strong> Lambda Invocations, Duration, Errors, Throttles</li>
          <li>• <strong>Storage:</strong> S3 Request Rate, 4XX Errors, Data Transfer</li>
          <li>• <strong>ML Metrics:</strong> Prediction Latency (custom), Model Accuracy (custom)</li>
        </ul>
      </div>
    </Section>
  </div>
);

export default function App() {
  const [activeTab, setActiveTab] = useState('overview');

  const tabs = [
    { id: 'overview', label: 'Overview', icon: Book },
    { id: 'sad', label: 'SAD', icon: FileText },
    { id: 'adr', label: 'ADRs', icon: Cpu },
    { id: 'security', label: 'Security', icon: Shield },
    { id: 'cost', label: 'Cost Analysis', icon: DollarSign },
    { id: 'runbook', label: 'Runbook', icon: AlertTriangle }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-indigo-50 via-purple-50 to-pink-50 p-6">
      <div className="max-w-6xl mx-auto">
        <div className="bg-white rounded-2xl shadow-2xl overflow-hidden">
          <div className="bg-gradient-to-r from-indigo-600 via-purple-600 to-pink-600 p-8 text-white">
            <h1 className="text-4xl font-bold mb-2">LinguaLearn AI</h1>
            <p className="text-lg opacity-90">Multilingual Learning Progress Predictor & Personalized Tutor Assistant</p>
            <p className="text-sm mt-2 opacity-80">Portfolio Project | Cloud-Native ML Application on AWS</p>
          </div>

          <div className="border-b border-gray-200 bg-gray-50">
            <div className="flex overflow-x-auto">
              {tabs.map(tab => {
                const Icon = tab.icon;
                return (
                  <button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id)}
                    className={`flex items-center gap-2 px-6 py-4 font-medium transition-all whitespace-nowrap ${
                      activeTab === tab.id
                        ? 'text-indigo-600 border-b-2 border-indigo-600 bg-white'
                        : 'text-gray-600 hover:text-indigo-600 hover:bg-gray-100'
                    }`}
                  >
                    <Icon size={18} />
                    {tab.label}
                  </button>
                );
              })}
            </div>
          </div>

          <div className="p-8">
            {activeTab === 'overview' && <OverviewSection />}
            {activeTab === 'sad' && <SADSection />}
            {activeTab === 'adr' && <ADRSection />}
            {activeTab === 'security' && <SecuritySection />}
            {activeTab === 'cost' && <CostSection />}
            {activeTab === 'runbook' && <RunbookSection />}
          </div>
        </div>
      </div>
    </div>
  );
}