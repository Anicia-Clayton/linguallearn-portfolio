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

---

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
