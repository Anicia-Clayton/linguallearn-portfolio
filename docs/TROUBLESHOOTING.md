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
