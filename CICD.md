# CI/CD Setup Guide

Complete guide for setting up GitHub Actions CI/CD for this Terraform project.

## 🎯 Overview

This project uses GitHub Actions for:
- **Automated Terraform Planning** on Pull Requests
- **Automated Terraform Apply** on merge to main
- **Security Scanning** (TFSec, Checkov, Gitleaks)
- **Code Quality** (TFLint, formatting checks)
- **Documentation Validation**

## 📋 Prerequisites

1. GitHub repository (public or private)
2. Active Snowflake account
3. Snowflake service account with appropriate permissions
4. RSA private key for authentication

## 🔧 Setup Instructions

### Step 1: Push Code to GitHub

```bash
cd /Users/filipblaafjell/Projects/sfguide-terraform-sample

# Initialize git (if not already)
git init

# Add files
git add .
git commit -m "Initial commit: Snowflake Terraform with CI/CD"

# Add remote
git remote add origin https://github.com/YOUR_USERNAME/sfguide-terraform-sample.git

# Push
git push -u origin main
```

### Step 2: Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these **Repository Secrets**:

| Secret Name | Value | Example |
|-------------|-------|---------|
| `SNOWFLAKE_ORG` | Your Snowflake organization name | `klvtwwp` |
| `SNOWFLAKE_ACCOUNT` | Your Snowflake account name | `yu90784` |
| `SNOWFLAKE_USER` | Terraform service account username | `TERRAFORM_SVC` |
| `SNOWFLAKE_PRIVATE_KEY` | Contents of your private key file | `-----BEGIN PRIVATE KEY-----\n...` |

**To get the private key value:**
```bash
cat ~/.ssh/snowflake_tf_snow_key.p8
```

Copy the **entire output** including the `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----` lines.

### Step 3: Configure GitHub Environment (Optional but Recommended)

For production deployments:

1. Go to Settings → Environments
2. Create environment: `production`
3. Configure protection rules:
   - ✅ Required reviewers (add team members)
   - ✅ Wait timer (optional delay before apply)
   - ✅ Deployment branches: `main` only

### Step 4: Enable GitHub Actions

1. Go to Actions tab in your repository
2. Click "I understand my workflows, go ahead and enable them"

## 🔄 Workflows

### 1. Terraform Plan (on Pull Request)

**File**: `.github/workflows/terraform-plan.yml`

**Triggers**: When a PR is opened/updated with changes to `.tf` files

**What it does**:
- ✅ Runs `terraform fmt` check
- ✅ Runs `terraform init`
- ✅ Runs `terraform validate`
- ✅ Runs `terraform plan`
- ✅ Posts plan output as PR comment

**Example PR Comment**:
```
#### Terraform Format and Style 🖌 success
#### Terraform Initialization ⚙️ success
#### Terraform Validation 🤖 success
#### Terraform Plan 📖 success

[Show Plan]
Plan: 5 to add, 0 to change, 0 to destroy.
...
```

### 2. Terraform Apply (on Merge to Main)

**File**: `.github/workflows/terraform-apply.yml`

**Triggers**: 
- Push to `main` branch
- Manual trigger via workflow_dispatch

**What it does**:
- ✅ Runs `terraform init`
- ✅ Runs `terraform plan`
- ✅ Runs `terraform apply -auto-approve`
- ✅ Outputs results to GitHub summary

**Manual Trigger**:
```
Actions → Terraform Apply → Run workflow → Select action (apply/destroy)
```

### 3. Terraform Lint (on PR and Push)

**File**: `.github/workflows/terraform-lint.yml`

**What it does**:
- ✅ Checks Terraform formatting
- ✅ Runs TFLint for best practices
- ✅ Validates Terraform syntax

### 4. Security Scan

**File**: `.github/workflows/security-scan.yml`

**Triggers**: PR, push to main, weekly on Sundays

**What it does**:
- ✅ TFSec - Terraform security scanning
- ✅ Checkov - Infrastructure security analysis
- ✅ Gitleaks - Secret scanning

### 5. Documentation Check

**File**: `.github/workflows/docs-check.yml`

**What it does**:
- ✅ Lints markdown files
- ✅ Verifies module documentation exists
- ✅ Checks README completeness

## 🚀 Usage Workflow

### Making Infrastructure Changes

**Step 1: Create a branch**
```bash
git checkout -b feature/add-sales-swimlane
```

**Step 2: Make changes**
```hcl
# In variables.tf, add:
sales = {
  environments = ["prod", "dev"]
  description  = "Sales department"
}
```

**Step 3: Commit and push**
```bash
git add variables.tf
git commit -m "Add sales swimlane"
git push origin feature/add-sales-swimlane
```

**Step 4: Create Pull Request**
- Go to GitHub and create a PR
- CI/CD automatically runs `terraform plan`
- Review the plan in the PR comments
- Request reviews from team

**Step 5: Merge**
- Once approved, merge the PR
- CI/CD automatically runs `terraform apply`
- Infrastructure is updated

**Step 6: Verify**
- Check Actions tab for apply status
- Verify in Snowflake that resources were created

## 🔒 Security Best Practices

### Secrets Management

✅ **DO:**
- Store all sensitive values in GitHub Secrets
- Use environment protection rules for production
- Rotate RSA keys regularly
- Use separate service accounts per environment

❌ **DON'T:**
- Commit `terraform.tfvars` to git
- Store private keys in code
- Use personal accounts for automation
- Skip PR reviews for infrastructure changes

### State File Management

**Current Setup**: Local state (not recommended for teams)

**Recommended for Production**: Remote state backend

Add to `providers.tf`:
```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "snowflake/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

**For Terraform Cloud**:
```hcl
terraform {
  cloud {
    organization = "your-org"
    workspaces {
      name = "snowflake-prod"
    }
  }
}
```

## 📊 Monitoring CI/CD

### GitHub Actions Dashboard

View workflow runs:
```
Repository → Actions → Select workflow
```

### Workflow Badges

Add to your README.md:
```markdown
![Terraform Plan](https://github.com/YOUR_USERNAME/sfguide-terraform-sample/actions/workflows/terraform-plan.yml/badge.svg)
![Terraform Apply](https://github.com/YOUR_USERNAME/sfguide-terraform-sample/actions/workflows/terraform-apply.yml/badge.svg)
![Security Scan](https://github.com/YOUR_USERNAME/sfguide-terraform-sample/actions/workflows/security-scan.yml/badge.svg)
```

### Notifications

Configure in: Settings → Notifications
- Email notifications on workflow failures
- Slack integration (via webhooks)

## 🐛 Troubleshooting

### "JWT token is invalid"

**Cause**: Private key mismatch or expired

**Fix**:
1. Verify the secret `SNOWFLAKE_PRIVATE_KEY` matches the public key in Snowflake
2. Regenerate keys if needed
3. Update GitHub secret

### "Error acquiring the state lock"

**Cause**: Previous run didn't complete

**Fix**:
```bash
terraform force-unlock <LOCK_ID>
```

### "Workflow doesn't trigger"

**Check**:
1. Workflows are enabled in Actions tab
2. Branch protections aren't blocking
3. File paths in `on.paths` match your changes

### "Apply fails but Plan succeeded"

**Cause**: State drift or concurrent modifications

**Fix**:
1. Run `terraform plan` again locally
2. Check for manual changes in Snowflake
3. Import or reconcile state

## 🎨 Customization

### Add Additional Environments

Create separate workflows for dev/staging:

```yaml
# .github/workflows/terraform-apply-dev.yml
on:
  push:
    branches:
      - develop

jobs:
  terraform-apply:
    environment: development
    # ... rest of workflow
```

### Add Terraform Cost Estimation

```yaml
- name: Terraform Cost Estimate
  uses: infracost/actions/setup@v2
  with:
    api-key: ${{ secrets.INFRACOST_API_KEY }}
```

### Add Automated Tests

```yaml
- name: Terraform Tests
  run: |
    cd tests
    terraform init
    terraform test
```

## 📈 Advanced Features

### Drift Detection

Create a scheduled workflow to detect configuration drift:

```yaml
# .github/workflows/drift-detection.yml
name: Drift Detection

on:
  schedule:
    - cron: '0 9 * * 1-5'  # Weekdays at 9 AM

jobs:
  detect-drift:
    runs-on: ubuntu-latest
    steps:
      # ... init terraform
      - name: Detect Drift
        run: |
          terraform plan -detailed-exitcode
          if [ $? -eq 2 ]; then
            echo "⚠️ Drift detected!"
            # Send notification
          fi
```

### Multi-Environment Deployments

Use Terraform workspaces or separate state files per environment.

### Integration Tests

Add post-apply validation:

```yaml
- name: Test Infrastructure
  run: |
    # Test database connectivity
    snowsql -a ${{ secrets.SNOWFLAKE_ACCOUNT }} \
            -u ${{ secrets.SNOWFLAKE_USER }} \
            --private-key-path /tmp/snowflake_key.p8 \
            -q "SHOW DATABASES;"
```

## 📞 Support

- **GitHub Actions Docs**: https://docs.github.com/en/actions
- **Terraform Cloud**: https://www.terraform.io/cloud
- **Snowflake Provider**: https://registry.terraform.io/providers/Snowflake-Labs/snowflake

---

**Last Updated**: 2026-01-13  
**Tested with**: Terraform 1.14.3, GitHub Actions  
**Status**: Production Ready ✅

