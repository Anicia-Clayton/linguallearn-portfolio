# Troubleshooting Guide

Quick reference for common issues encountered during development and their solutions.

---

## Infrastructure & Terraform

### PostgreSQL Version Not Available

**Error:**
```
Error: creating RDS DB Instance: operation error RDS: CreateDBInstance
api error InvalidParameterCombination: Cannot find version 14.10 for postgres
```

**Root Cause:** AWS RDS continuously updates available PostgreSQL versions. Specific minor versions (like 14.10) may be deprecated or unavailable in your region.

**Solution:**
```hcl
# In rds.tf, change:
engine_version = "14.10"  # ❌ Specific version may not exist

# To:
engine_version = "14"     # ✅ Uses latest 14.x automatically
```

**Commands to check available versions:**
```bash
# List all PostgreSQL 14.x versions in your region
aws rds describe-db-engine-versions \
  --engine postgres \
  --engine-version 14 \
  --query 'DBEngineVersions[*].[EngineVersion]' \
  --output text
```

**Best Practice:**
- **Development:** Use major version only (`"14"`) for automatic updates
- **Production:** Pin to specific version (`"14.13"`) for stability

---

### Line Ending Warnings (LF vs CRLF)

**Warning:**
```
warning: in the working copy of '.terraform.lock.hcl', LF will be replaced by CRLF
the next time Git touches it
```

**Root Cause:** Git on Windows attempts to convert Unix-style line endings (LF) to Windows-style (CRLF), which can cause issues with Terraform lock files and shell scripts in CI/CD pipelines.

**Solution:**

**1. Create `.gitattributes` file in project root:**
```gitattributes
# Global line-ending policy
* text=auto eol=lf

# Terraform-specific files
*.tf       text eol=lf
*.tfvars   text eol=lf
*.hcl      text eol=lf
*.lock.hcl text eol=lf

# Shell scripts (bash) - must use LF for Linux
*.sh       text eol=lf

# PowerShell scripts can use CRLF if needed
*.ps1      text eol=crlf

# YAML/JSON files
*.yml      text eol=lf
*.yaml     text eol=lf
*.json     text eol=lf

# Markdown
*.md       text eol=lf

# Binary files (no conversion)
*.png      binary
*.jpg      binary
*.pdf      binary
*.zip      binary
```

**2. Create `.editorconfig` file for consistent editor settings:**
```ini
root = true

[*]
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.{tf,hcl,tfvars}]
indent_style = space
indent_size = 2

[*.sh]
indent_style = space
indent_size = 2

[*.md]
trim_trailing_whitespace = false
```

**3. Normalize existing files:**
```bash
git add --renormalize .
git commit -m "Normalize line endings to LF"
```

**Why This Matters:**
- Terraform lock files use checksums that can fail if line endings change
- Shell scripts executed in Linux CI/CD environments require LF
- Prevents "noisy" diffs showing every line as changed

---

## AWS CLI Issues

### "Unknown output type: JSON" in Windows CMD

**Error:** When running AWS CLI commands in Windows CMD, you get "Unknown output type: JSON"

**Root Cause:** CMD interprets quotes differently than bash/PowerShell

**Solution:** Add `--output text` or `--output table` to commands:
```cmd
# Instead of:
aws ec2 describe-instances --query "Reservations[0].Instances[0].State"

# Use:
aws ec2 describe-instances --query Reservations[0].Instances[0].State --output text
```

**Or use PowerShell/WSL instead:**
```powershell
# PowerShell works with original syntax
aws ec2 describe-instances --query "Reservations[0].Instances[0].State"
```

```bash
# WSL bash also works
wsl aws ec2 describe-instances --query "Reservations[0].Instances[0].State"
```

---

## Git & Version Control

### Nested Git Repository Issues
See [Lessons Learned: Git Repository Restructure](docs/lessons-learned/git-nested-repo-conflict.md) for detailed walkthrough of resolving accidental nested repos with diverged branches.

### Large Files in Git History

**Issue:** Accidentally committed large files (e.g., terraform.tfstate) causing slow clones

**Prevention:**
```gitignore
# Add to .gitignore before first commit
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl  # Optional - some teams commit this
terraform.tfvars     # Contains secrets
```

**If already committed:**
```bash
# Remove from Git history (use with caution)
git filter-branch --tree-filter 'rm -f terraform.tfstate' HEAD
git push --force
```


## AWS Systems Manager (SSM)

### Session Manager Plugin Not Found

**Error:**
```
SessionManagerPlugin is not found. Please refer to SessionManager Documentation here:
http://docs.aws.amazon.com/console/systems-manager/session-manager-plugin-not-found
```

**Root Cause:** The AWS CLI requires a separate Session Manager plugin to handle SSM connections. It's not included by default with the AWS CLI installation.

**Solution:**

**For Windows:**
1. Download the installer:
   - [Session Manager Plugin (64-bit)](https://s3.amazonaws.com/session-manager-downloads/plugin/latest/windows/SessionManagerPluginSetup.exe)

2. Run the installer (double-click the .exe file)

3. **Close and reopen CMD** (PATH needs to refresh)

4. Verify installation:
```cmd
session-manager-plugin
```

**If plugin still not recognized after reopening CMD:**
```cmd
# Add to PATH temporarily
set PATH=%PATH%;C:\Program Files\Amazon\SessionManagerPlugin\bin

# Or add permanently via System Environment Variables
```

**Then test SSM connection:**
```cmd
aws ssm start-session --target i-YOUR-INSTANCE-ID
```

---

### AWS CLI and jq Not Found on EC2 Instance

**Error (when SSHed into EC2):**
```bash
sh: 1: aws: not found
sh: 3: jq: not found
```

**Root Cause:** You're connected to the EC2 instance via SSM, and the AWS CLI and `jq` utility aren't installed yet. This is expected if your user_data script hasn't run or failed.

**Solution:**

**Check if user_data script ran:**
```bash
sudo cat /var/log/cloud-init-output.log | tail -50
```

**Install manually (quick fix):**
```bash
# Update package manager
sudo apt update

# Install AWS CLI
sudo apt install awscli -y

# Install jq (JSON parser)
sudo apt install jq -y
```

**Verify installation:**
```bash
aws --version
jq --version
```

**Test Secrets Manager access:**
```bash
aws secretsmanager get-secret-value \
  --secret-id linguallearn-rds-credentials-dev \
  --region us-east-1 \
  --query SecretString --output text | jq .
```

**Note:** If the command returns nothing, ensure the EC2 IAM role has `SecretsManagerReadWrite` permissions.

---

### S3 Access Denied (403 Forbidden) from EC2

**Error:**
```bash
aws s3 cp s3://bucket-name/file.sql /home/ubuntu/file.sql
fatal error: An error occurred (403) when calling the HeadObject operation: Forbidden
```

**Context:** When uploading a large database schema file (428 lines) to EC2 for execution against RDS, the most reliable method is to use S3 as a transfer point rather than copy/paste or SCP (which requires SSH keys). However, EC2 instances need explicit S3 permissions.

**Root Cause:** The EC2 instance's IAM role doesn't have permissions to read from S3 buckets.

**Solution:**

**Step 1: Identify the IAM role attached to your EC2 instance**

From your local machine:
```bash
# Get instance profile ARN
aws ec2 describe-instances \
  --instance-ids i-YOUR-INSTANCE-ID \
  --query "Reservations[0].Instances[0].IamInstanceProfile.Arn" \
  --output text

# Extract the actual role name from the instance profile
aws iam get-instance-profile \
  --instance-profile-name YOUR-INSTANCE-PROFILE-NAME \
  --query "InstanceProfile.Roles[0].RoleName" \
  --output text
```

**Example output:**
```
Instance Profile: linguallearn-ec2-profile-dev
Role Name: linguallearn-ec2-role-dev
```

**Step 2: Attach S3 read permissions to the role**

```bash
aws iam attach-role-policy \
  --role-name linguallearn-ec2-role-dev \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
```

**Note:** Use the **role name**, not the instance profile name.

**Step 3: Wait 30 seconds for permissions to propagate**

IAM policy changes can take 10-30 seconds to take effect.

**Step 4: Retry the S3 copy command**

```bash
aws s3 cp s3://bucket-name/file.sql /tmp/file.sql
```

You should now see:
```
download: s3://bucket-name/file.sql to ./file.sql
```

**Best Practice - Add S3 Permissions in Terraform:**

To prevent this issue in the future, add S3 permissions to your EC2 IAM role in `terraform/iam.tf`:

```hcl
resource "aws_iam_role_policy_attachment" "ec2_s3_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
```

**Use Case:** This is particularly useful when:
- Uploading large SQL schema files (100+ lines) to EC2
- Transferring configuration files or scripts from local to EC2
- Downloading application code or dependencies from S3 to EC2
- EC2 needs to access data stored in S3 buckets

**Cost Impact:** Negligible. S3 reads cost ~$0.0004 per 1,000 requests.

---

## Development Environment

### Python Virtual Environment Issues

**Issue:** Package conflicts or wrong Python version

**Solution:**
```bash
# Create fresh virtual environment
python3 -m venv venv

# Activate (Linux/Mac)
source venv/bin/activate

# Activate (Windows CMD)
venv\Scripts\activate.bat

# Activate (Windows PowerShell)
venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt
```

## RDS Password Authentication Failures After Password Reset

**Symptoms:**
- API service fails to start with `psycopg2.OperationalError: password authentication failed`
- Password displays differently in different AWS CLI commands
- Connection works in psql but API still fails

**Root Cause:**
1. **Password encoding issues**: Complex passwords with special characters (e.g., `<`, `>`, `!`) get Unicode-escaped in JSON (`\u003c`) causing mismatches between displayed and actual values
2. **Stale connection pools**: API service caches database connections; restarting doesn't always clear the old connections with old passwords
3. **Secrets Manager sync lag**: RDS password reset doesn't automatically update AWS Secrets Manager

**Solution:**

### Quick Fix (Recommended for Development):
Use a simple password without special characters:
```bash
# CMD: Reset RDS password
aws rds modify-db-instance --db-instance-identifier linguallearn-db-dev --region us-east-1 --master-user-password "TempPassword2025" --apply-immediately

# CMD: Wait 2-3 minutes, verify status is 'available'
aws rds describe-db-instances --db-instance-identifier linguallearn-db-dev --region us-east-1 --query "DBInstances[0].DBInstanceStatus" --output text

# CMD: Update Secrets Manager to match
aws secretsmanager update-secret --secret-id linguallearn-db-password-dev --region us-east-1 --secret-string "{\"username\":\"postgres\",\"password\":\"TempPassword2025\",\"host\":\"linguallearn-db-dev.cen4mk6u4h0n.us-east-1.rds.amazonaws.com\",\"port\":5432,\"dbname\":\"linguallearn\"}"

# Session Manager: Force complete API restart
sudo systemctl stop linguallearn-api
sudo pkill -f uvicorn
sleep 5
sudo systemctl start linguallearn-api
sudo systemctl status linguallearn-api
```

### Verification Steps:

1. **Confirm Secrets Manager updated:**
```bash
   aws secretsmanager get-secret-value --secret-id linguallearn-db-password-dev --region us-east-1 --query SecretString --output text
```

2. **Test database connection manually:**
```bash
   psql -h linguallearn-db-dev.cen4mk6u4h0n.us-east-1.rds.amazonaws.com -U postgres -d linguallearn
   # Password: TempPassword2025
```

3. **Check API logs for confirmation:**
```bash
   sudo journalctl -u linguallearn-api -n 50 --no-pager
```

**Prevention:**
- Use simple passwords (letters + numbers only) during development
- Always update Secrets Manager immediately after resetting RDS password
- Do a full stop → kill → wait → start cycle when changing database credentials
- Consider using AWS Secrets Manager rotation to keep passwords in sync automatically

**Related Issues:**
- Special characters in passwords: `<`, `>`, `!`, `{`, `}`, `\` can cause encoding problems
- Connection pool caching: Service restart doesn't always clear cached connections
- Unicode escape sequences: `\u003c` (JSON) vs `<` (actual character)

---

## Scikit-learn Feature Name Warnings During Model Predictions

**Symptoms:**
- Warning appears during model predictions: `UserWarning: X does not have valid feature names, but LinearRegression was fitted with feature names`
- Warning repeats for every prediction
- Predictions still work correctly but logs are cluttered

**Root Cause:**
- Model was trained using pandas DataFrame with column names (`days_since_last_review`, `review_count`, `difficulty_score`)
- Predictions were made using numpy arrays without column names
- Scikit-learn (v1.0+) enforces consistency between training and prediction input formats

**Solution:**

### Option 1: Use DataFrame for Predictions (Recommended)

Update `predict_recall_probability()` in `api/models/forgetting_curve.py`:
```python
def predict_recall_probability(self, days_since_review, review_count, difficulty_score):
    """Predict probability of successful recall"""
    if self.model is None:
        return np.exp(-self.default_decay_rate * days_since_review)

    # Use DataFrame with proper column names (matches training data)
    features = pd.DataFrame({
        'days_since_last_review': [days_since_review],
        'review_count': [review_count],
        'difficulty_score': [difficulty_score]
    })

    prediction = self.model.predict(features)[0]
    return max(0.0, min(1.0, prediction))
```

**Benefits:**
- Eliminates warnings
- More explicit and readable
- Prevents column order mistakes
- Industry best practice

### Option 2: Suppress Warning (Quick Fix)

Add to top of `api/models/forgetting_curve.py`:
```python
import warnings
warnings.filterwarnings('ignore', message='X does not have valid feature names')
```

**Benefits:**
- Fastest solution (30 seconds)
- Useful for prototyping/testing
- Predictions still work correctly

**Trade-offs:**
- Hides the underlying issue
- Not recommended for production code

### Option 3: Train Without Column Names

Change training to use numpy arrays:
```python
def train(self, learning_sessions_data):
    X = learning_sessions_data[['days_since_last_review', 'review_count', 'difficulty_score']].values
    y = learning_sessions_data['successful_recall'].values

    self.model = LinearRegression()
    self.model.fit(X, y)
    return self.model.score(X, y)
```

**Benefits:**
- Slightly faster predictions (~0.004ms difference)
- Consistency between training and prediction

**Trade-offs:**
- Less readable code
- Harder to debug column order issues

**Recommendation:**
Use **Option 1** (DataFrame for predictions) for portfolio and production code. It's the cleanest, most maintainable solution and follows scikit-learn best practices.

**Prevention:**
Always use the same data structure (DataFrame or numpy array) for both training and prediction to maintain consistency.

**Related Issues:**
- Column name mismatches: Ensure training column names exactly match prediction DataFrame columns
- Column order errors: DataFrames prevent this; numpy arrays are position-dependent

# Lambda ML Layer Deployment: Complete Troubleshooting Guide

## Overview
Deploying scikit-learn to AWS Lambda is challenging due to:
1. Lambda's 250MB unzipped size limit
2. Python version compatibility (Lambda uses Python 3.11)
3. Platform compatibility (Lambda runs on Linux, development on Windows)
4. Large dependency sizes (scikit-learn + numpy + pandas + scipy ≈ 250MB)

This guide documents the complete solution that works.

---

## Common Errors and Root Causes

### Error 1: "RequestEntityTooLargeException: Request must be smaller than 70167211 bytes"

**Symptoms:**
```
Error: creating Lambda Function: operation error Lambda: CreateFunction,
https response error StatusCode: 413, RequestID: ...,
RequestEntityTooLargeException: Request must be smaller than 70167211 bytes
```

**Root Cause:**
- Attempting direct upload of Lambda function with scikit-learn dependencies
- Direct upload limit: 50MB zipped / 250MB unzipped
- Scikit-learn alone is ~180MB unzipped

**Solution:**
- Use S3 for deployment package storage
- Separate dependencies into Lambda layers
- Use layers for large dependencies, slim function code for business logic

---

### Error 2: "InvalidParameterValueException: Unzipped size must be smaller than 262144000 bytes"

**Symptoms:**
```
Error: publishing Lambda Layer: operation error Lambda: PublishLayerVersion,
https response error StatusCode: 400, RequestID: ...,
InvalidParameterValueException: Unzipped size must be smaller than 262144000 bytes
```

**Root Cause:**
- Lambda layer exceeds 250MB unzipped limit
- Installing full scikit-learn with all dependencies and documentation

**Solution:**
- Aggressively strip unnecessary files from layer
- Remove: tests, benchmarks, docs, examples, .dist-info, .egg-info
- Target: <220MB unzipped to have buffer

---

### Error 3: "No module named 'sklearn.__check_build._check_build'"

**Symptoms:**
```
{"statusCode": 500, "body": "{\"error\": \"No module named 'sklearn.__check_build._check_build'
...
Contents of /opt/python/sklearn/__check_build:
_check_build.cp312-win_amd64.pyd
...
It seems that scikit-learn has not been built correctly."}
```

**Root Cause:**
- Installed Windows binaries (.pyd, cp312-win_amd64) on Lambda (Linux environment)
- Lambda cannot execute Windows-compiled Python extensions

**Solution:**
- Install packages in WSL (Linux environment)
- Use `--platform manylinux2014_x86_64` flag
- Ensure Linux-compatible binaries (.so files, not .pyd)

---

### Error 4: Wrong Python Version (3.12 vs 3.11)

**Symptoms:**
```
{"statusCode": 500, "body": "{\"error\": \"No module named 'sklearn.__check_build._check_build'
...
_check_build.cpython-312-x86_64-linux-gnu.so
..."}
```

**Root Cause:**
- WSL has Python 3.12 installed
- Lambda uses Python 3.11
- Downloaded Python 3.12 binaries incompatible with Lambda's Python 3.11 runtime

**Solution:**
- Use `--python-version 3.11` flag in pip install
- Forces pip to download Python 3.11 compatible binaries
- Use `--implementation cp` to ensure CPython implementation

---

### Error 5: "No module named 'pandas'"

**Symptoms:**
```
{"statusCode": 500, "body": "{\"error\": \"No module named 'pandas'\"}"}
```

**Root Cause:**
- Handler code uses pandas DataFrame for predictions
- Pandas not included in Lambda layer

**Solution:**
- Add pandas to layer installation
- Maintain consistency: if training uses pandas, inference must too
- Alternative: Use numpy arrays everywhere (but causes scikit-learn warnings)

---

### Error 6: "'dict' object has no attribute 'predict_recall_probability'"

**Symptoms:**
```
{"statusCode": 500, "body": "{\"error\": \"'dict' object has no attribute 'predict_recall_probability'\"}"}
```

**Root Cause:**
- Model saved as dictionary: `{'sklearn_model': model, 'decay_rate': 0.3}`
- Handler expected ForgettingCurveModel instance with methods
- Pickle loads dictionary, not class instance

**Solution:**
- Update handler to expect dictionary structure
- Extract sklearn model: `model_dict['sklearn_model']`
- Implement prediction logic directly in handler

---

## Complete Working Solution

### Step 1: Create Optimized Lambda Layer (in CMD using WSL)

```cmd
REM Remove any old attempts
wsl rm -rf lambda/ml_layer_complete

REM Create proper directory structure
wsl mkdir -p lambda/ml_layer_complete/python

REM Install packages for Python 3.11 on Linux
wsl pip3 install scikit-learn==1.3.2 pandas numpy scipy joblib threadpoolctl -t lambda/ml_layer_complete/python --platform manylinux2014_x86_64 --python-version 3.11 --only-binary=:all: --implementation cp

REM Aggressively strip unnecessary files
wsl bash -c "cd lambda/ml_layer_complete/python && rm -rf *.dist-info *.egg-info __pycache__ pip* setuptools* wheel* pkg_resources* easy_install* _pytest pytest && find . -type d -name 'tests' -exec rm -rf {} + 2>/dev/null && find . -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null && find . -type d -name 'benchmarks' -exec rm -rf {} + 2>/dev/null && find . -name '*.pyc' -delete && find . -name '*.pyo' -delete && find . -name '*.a' -delete && find . -name '*.la' -delete"

REM Remove documentation and examples
wsl bash -c "cd lambda/ml_layer_complete/python && find . -type d -name 'doc' -exec rm -rf {} + 2>/dev/null && find . -type d -name 'docs' -exec rm -rf {} + 2>/dev/null && find . -type d -name 'examples' -exec rm -rf {} + 2>/dev/null && find . -type f -name '*.md' -delete && find . -type f -name '*.rst' -delete && find . -type f -name '*.txt' -delete"

REM Verify size is under 250MB
wsl du -sh lambda/ml_layer_complete/python

REM Package the layer
wsl bash -c "cd lambda/ml_layer_complete && python3 -c \"import shutil; shutil.make_archive('../ml_layer_complete_stripped', 'zip', '.')\""

REM Check zipped size
wsl ls -lh lambda/ml_layer_complete_stripped.zip

REM Upload to S3
aws s3 cp lambda\ml_layer_complete_stripped.zip s3://YOUR-DATA-LAKE-BUCKET/lambda/ml_layer_complete.zip
```

**Expected Output:**
```
218M    lambda/ml_layer_complete/python
-rwxrwxrwx 1 user user 78M Dec 11 16:45 lambda/ml_layer_complete_stripped.zip
```

**Size Breakdown:**
- Unzipped: ~218MB (under 250MB limit ✅)
- Zipped: ~78MB
- Contains: scikit-learn 1.3.2, pandas, numpy, scipy, joblib

---

### Step 2: Create Slim Lambda Function Package

**handler.py:**
```python
# lambda/ml_inference/handler.py
import json
import boto3
import pickle
import os
import numpy as np
from datetime import datetime

s3 = boto3.client('s3')
MODEL_BUCKET = os.environ['MODEL_BUCKET']
MODEL_KEY = 'models/forgetting_curve_v1.pkl'

model_data = None

def load_model():
    """Download and load model from S3"""
    global model_data
    if model_data is None:
        print(f"Loading model from s3://{MODEL_BUCKET}/{MODEL_KEY}")
        response = s3.get_object(Bucket=MODEL_BUCKET, Key=MODEL_KEY)
        model_bytes = response['Body'].read()
        model_data = pickle.loads(model_bytes)
        print("Model loaded successfully")
    return model_data

def predict_recall_probability(model_dict, days_since_review, review_count, difficulty_score):
    """Predict probability of successful recall"""
    sklearn_model = model_dict['sklearn_model']

    # Use pandas DataFrame with proper column names
    import pandas as pd
    features = pd.DataFrame({
        'days_since_last_review': [days_since_review],
        'review_count': [review_count],
        'difficulty_score': [difficulty_score]
    })

    prediction = sklearn_model.predict(features)[0]
    return max(0.0, min(1.0, prediction))

def get_optimal_review_time(recall_probability, threshold=0.7):
    """Calculate optimal review timing"""
    return 0 if recall_probability < threshold else 1

def lambda_handler(event, context):
    """Lambda handler for ML predictions"""
    try:
        body = json.loads(event.get('body', '{}')) if isinstance(event.get('body'), str) else event

        card_id = body.get('card_id')
        days_since_review = body['days_since_review']
        review_count = body['review_count']
        difficulty_score = body['difficulty_score']

        print(f"Prediction request: card_id={card_id}, days={days_since_review}, reviews={review_count}, difficulty_score={difficulty_score}")

        model_dict = load_model()
        recall_probability = predict_recall_probability(
            model_dict, days_since_review, review_count, difficulty_score
        )

        optimal_days = get_optimal_review_time(recall_probability)

        print(f"Prediction: recall_prob={recall_probability:.2f}, optimal_days={optimal_days}")

        return {
            'statusCode': 200,
            'body': json.dumps({
                'card_id': card_id,
                'recall_probability': float(recall_probability),
                'optimal_review_days': int(optimal_days),
                'recommendation': 'Review today!' if optimal_days == 0 else 'Review tomorrow',
                'model_version': 'v1',
                'timestamp': str(datetime.now())
            })
        }

    except KeyError as e:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': f'Missing required field: {str(e)}'})
        }
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
```

**Package and Upload:**
```cmd
REM Package slim function (just handler.py)
wsl bash -c "cd lambda/ml_inference && python3 -c \"import shutil; shutil.make_archive('../ml_inference_slim', 'zip', '.', 'handler.py')\""

REM Upload to S3
aws s3 cp lambda\ml_inference_slim.zip s3://YOUR-DATA-LAKE-BUCKET/lambda/ml_inference.zip
```

---

### Step 3: Terraform Configuration

```hcl
# terraform/lambda.tf

# Complete scikit-learn layer (optimized to fit under 250MB)
resource "aws_lambda_layer_version" "sklearn_complete" {
  layer_name          = "${var.project_name}-sklearn-complete-${var.environment}"
  s3_bucket           = aws_s3_bucket.data_lake.id
  s3_key              = "lambda/ml_layer_complete.zip"
  compatible_runtimes = ["python3.11"]
  description         = "Scikit-learn with numpy, scipy, pandas (optimized)"
}

# Lambda function for ML inference
resource "aws_lambda_function" "ml_inference" {
  s3_bucket     = aws_s3_bucket.data_lake.id
  s3_key        = "lambda/ml_inference.zip"
  function_name = "${var.project_name}-ml-inference-${var.environment}"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 512

  # Use optimized layer
  layers = [aws_lambda_layer_version.sklearn_complete.arn]

  environment {
    variables = {
      MODEL_BUCKET = aws_s3_bucket.data_lake.id
    }
  }
}

# IAM policy for Lambda to access S3 data lake (for model loading)
resource "aws_lambda_role_policy" "lambda_ml_s3" {
  name = "lambda-ml-s3-access"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.data_lake.arn}/models/*"
      }
    ]
  })
}
```

**Deploy:**
```cmd
cd terraform
terraform apply
cd ..
```

---

### Step 4: Testing

**Create test event:**
```cmd
REM Use PowerShell to create clean JSON
powershell
'{"card_id": 123, "days_since_review": 7, "review_count": 3, "difficulty_score": 0.6}' | Out-File -FilePath test-event.json -Encoding ascii -NoNewline
exit
```

**Invoke Lambda:**
```cmd
aws lambda invoke --function-name linguallearn-ml-inference-dev --payload file://test-event.json --cli-binary-format raw-in-base64-out --region us-east-1 output.json

type output.json
```

**Expected Success Output:**
```json
{
  "statusCode": 200,
  "body": "{\"card_id\": 123, \"recall_probability\": 0.6100281820804448, \"optimal_review_days\": 0, \"recommendation\": \"Review today!\", \"model_version\": \"v1\", \"timestamp\": \"2025-12-11 23:29:34.434149\"}"
}
```

**Check CloudWatch Logs:**
```cmd
aws logs tail /aws/lambda/linguallearn-ml-inference-dev --follow --region us-east-1
```

**Expected Log Output:**
```
START RequestId: abc123...
Prediction request: card_id=123, days=7, reviews=3, difficulty_score=0.6
Loading model from s3://linguallearn-data-lake-dev-a2af9b40/models/forgetting_curve_v1.pkl
Model loaded successfully
Prediction: recall_prob=0.61, optimal_days=0
END RequestId: abc123...
REPORT RequestId: abc123... Duration: 234.62 ms Memory Used: 91 MB
```

---

## Critical Requirements Checklist

✅ **Python Version:** 3.11 (match Lambda runtime)
✅ **Platform:** manylinux2014_x86_64 (Linux binaries)
✅ **Implementation:** CPython (cp)
✅ **Layer Size:** <250MB unzipped (<220MB recommended)
✅ **File Optimization:** Remove tests, docs, benchmarks, .dist-info
✅ **Dependencies:** scikit-learn, pandas, numpy, scipy, joblib
✅ **Deployment:** S3 for both layer and function code
✅ **Handler:** Uses pandas DataFrame for consistency with training

---

## Prevention Tips

1. **Always install for Linux when targeting Lambda:**
   ```bash
   --platform manylinux2014_x86_64 --python-version 3.11 --only-binary=:all: --implementation cp
   ```

2. **Check layer size before deployment:**
   ```bash
   wsl du -sh lambda/ml_layer_complete/python
   ```
   Target: <220MB for safety buffer

3. **Use WSL for package installation:**
   - Ensures Linux binaries
   - Avoids Windows .pyd files
   - Proper platform compatibility

4. **Strip aggressively:**
   - Remove all .dist-info and .egg-info
   - Delete tests, benchmarks, docs, examples
   - Remove .pyc, .pyo, .a, .la files
   - Delete markdown and text documentation

5. **Test locally before deploying:**
   ```bash
   wsl python3 -c "import sklearn; import pandas; import numpy; print('OK')"
   ```

6. **Use pandas consistently:**
   - If training uses pandas DataFrames, inference should too
   - Prevents scikit-learn feature name warnings
   - More maintainable code

---

## Alternative Solutions (If Still Too Large)

### Option 1: Lambda Container Images
For dependencies >250MB, use Docker containers (up to 10GB):

```dockerfile
FROM public.ecr.aws/lambda/python:3.11

RUN pip install scikit-learn pandas numpy scipy

COPY handler.py ${LAMBDA_TASK_ROOT}

CMD ["handler.lambda_handler"]
```

**Pros:** No size limits, full control
**Cons:** More complex, slower cold starts

### Option 2: Amazon SageMaker
For complex ML workloads:
- Managed model hosting
- Automatic scaling
- Built-in monitoring
- Higher cost

### Option 3: Slim Models
Use lightweight alternatives:
- `scikit-learn-intelex` (Intel optimization)
- Model quantization
- Feature selection to reduce model size

---

## Related Issues

- **Slow cold starts:** Expected with ML layers (~2-3 seconds first invocation)
- **Memory errors:** Increase Lambda memory to 512MB or 1024MB
- **Import errors:** Verify layer attached and runtime matches (Python 3.11)
- **Model loading fails:** Check S3 permissions and MODEL_BUCKET environment variable

---

## Key Learnings

1. **Platform matters:** Windows binaries don't work on Lambda (Linux)
2. **Python version matters:** 3.11 vs 3.12 binaries are incompatible
3. **Size optimization is critical:** Aggressive file removal necessary
4. **Consistency matters:** Use same data structures (pandas) in training and inference
5. **WSL is essential:** For Linux-compatible package installation on Windows

---

## Success Metrics

✅ Layer deploys without size errors
✅ Lambda function invokes successfully
✅ Model loads from S3 without errors
✅ Predictions return valid probability values (0.0-1.0)
✅ CloudWatch logs show "Model loaded successfully"
✅ Response time <3 seconds (including cold start)
✅ Memory usage <200MB

---

## References

- [AWS Lambda Limits](https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html)
- [AWS Lambda Layers](https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html)
- [Scikit-learn Documentation](https://scikit-learn.org/stable/)
- [Pandas Documentation](https://pandas.pydata.org/docs/)


## Quick Reference: Common Commands

### Terraform
```bash
# Validate configuration
terraform validate

# Check what will change
terraform plan

# Show current state
terraform show

# Destroy specific resource
terraform destroy -target=aws_instance.api_server

# Force unlock state (use carefully)
terraform force-unlock <LOCK_ID>
```

### AWS CLI - Instance Status
```bash
# Check EC2 status
aws ec2 describe-instances \
  --instance-ids i-xxxxx \
  --query 'Reservations[0].Instances[0].State.Name' \
  --output text

# Check RDS status
aws rds describe-db-instances \
  --db-instance-identifier db-name \
  --query 'DBInstances[0].DBInstanceStatus' \
  --output text

# Check SSM connectivity
aws ssm describe-instance-information \
  --filters Key=InstanceIds,Values=i-xxxxx \
  --output text
```

### Git
```bash
# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# Stash changes temporarily
git stash
git stash pop

# View file history
git log --follow filename.tf
```

## Additional Resources

- [AWS CLI Command Reference](https://docs.aws.amazon.com/cli/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Git Line Endings Guide](https://docs.github.com/en/get-started/getting-started-with-git/configuring-git-to-handle-line-endings)
