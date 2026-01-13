# Snowflake Swimlane Architecture with Terraform

[![Terraform Plan](https://github.com/filipblaafjell/sfguide-terraform-sample/actions/workflows/terraform-plan.yml/badge.svg)](https://github.com/filipblaafjell/sfguide-terraform-sample/actions/workflows/terraform-plan.yml)
[![Terraform Apply](https://github.com/filipblaafjell/sfguide-terraform-sample/actions/workflows/terraform-apply.yml/badge.svg)](https://github.com/filipblaafjell/sfguide-terraform-sample/actions/workflows/terraform-apply.yml)
[![Security Scan](https://github.com/filipblaafjell/sfguide-terraform-sample/actions/workflows/security-scan.yml/badge.svg)](https://github.com/filipblaafjell/sfguide-terraform-sample/actions/workflows/security-scan.yml)

A production-ready Terraform configuration for managing Snowflake data platform with isolated swimlanes for different business units (Finance, Marketing, Master) across multiple environments (prod, dev).

**✨ Features:** Automated CI/CD, Security Scanning, Modular Architecture, Complete Documentation

## 🏗️ Architecture Overview

### Swimlane Design

Each swimlane is an isolated data environment with:
- **Database** with multiple schemas (RAW, STAGING, ANALYTICS)
- **Dedicated Warehouse** for compute isolation
- **Role-Based Access Control (RBAC)** with READ/WRITE/ADMIN roles
- **Environment Separation** (prod and dev)

### Created Resources

#### Per Swimlane/Environment (6 total: 3 swimlanes × 2 environments)
- 1 Database (e.g., `FINANCE_PROD_DB`)
- 3 Schemas per database: `RAW`, `STAGING`, `ANALYTICS`
- 1 Warehouse (e.g., `FINANCE_PROD_WH`)
- 2 Roles: `READ` and `WRITE`

#### Per Swimlane (3 total)
- 1 ADMIN role spanning both environments

#### Sample Users
- Finance Analyst (read access to prod/dev)
- Finance Engineer (write to dev, read to prod)
- Marketing Analyst (read access to prod/dev)
- Marketing Engineer (write to dev, read to prod)
- Master Admin (admin access to master swimlane)

## 📁 Project Structure

```
.
├── modules/
│   └── swimlane/              # Reusable swimlane module
│       ├── main.tf            # Database, schemas, warehouse, roles
│       ├── variables.tf       # Module inputs
│       ├── outputs.tf         # Module outputs
│       └── README.md          # Module documentation
├── providers.tf               # Snowflake provider configurations
├── locals.tf                  # Local variables
├── swimlanes.tf               # Swimlane module instantiations
├── admin_roles.tf             # Admin roles spanning environments
├── users.tf                   # Sample user definitions
├── variables.tf               # Root module variables
├── outputs.tf                 # Root module outputs
├── terraform.tfvars.example   # Example configuration
└── README.md                  # This file
```

## 🚀 Getting Started

### Prerequisites

1. **Terraform** >= 1.0
2. **Snowflake Account** with appropriate permissions
3. **RSA Key Pair** for authentication

### Step 1: Create Snowflake Service Account

```sql
-- In Snowflake, run as ACCOUNTADMIN:
USE ROLE ACCOUNTADMIN;

-- Create service account
CREATE USER TERRAFORM_SVC
  DEFAULT_ROLE = SYSADMIN
  MUST_CHANGE_PASSWORD = FALSE;

-- Grant roles
GRANT ROLE SYSADMIN TO USER TERRAFORM_SVC;
GRANT ROLE SECURITYADMIN TO USER TERRAFORM_SVC;
GRANT ROLE USERADMIN TO USER TERRAFORM_SVC;
```

### Step 2: Generate RSA Key Pair

```bash
# Generate private key
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out ~/.ssh/snowflake_tf_snow_key.p8 -nocrypt

# Generate public key
openssl rsa -in ~/.ssh/snowflake_tf_snow_key.p8 -pubout -out ~/.ssh/snowflake_tf_snow_key.pub

# Extract public key for Snowflake (remove headers)
grep -v "BEGIN PUBLIC" ~/.ssh/snowflake_tf_snow_key.pub | grep -v "END PUBLIC" | tr -d '\n' > ~/.ssh/snowflake_tf_snow_key_clean.pub
```

### Step 3: Assign Public Key to Service Account

```sql
-- In Snowflake:
USE ROLE ACCOUNTADMIN;

ALTER USER TERRAFORM_SVC SET RSA_PUBLIC_KEY='<paste contents of snowflake_tf_snow_key_clean.pub>';
```

### Step 4: Configure Terraform

```bash
# Copy example config
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
vim terraform.tfvars
```

Required configuration in `terraform.tfvars`:

```hcl
organization_name = "your_org_name"      # e.g., "acme"
account_name      = "your_account_name"  # e.g., "xy12345"
terraform_user    = "TERRAFORM_SVC"
private_key_path  = "~/.ssh/snowflake_tf_snow_key.p8"

environment        = "production"
warehouse_size     = "SMALL"
warehouse_auto_suspend = 60
```

### Step 5: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Apply configuration
terraform apply

# View outputs
terraform output quick_reference
```

## 🎯 Role Hierarchy

```
ACCOUNTADMIN
  └── SYSADMIN
        ├── {SWIMLANE}_ADMIN_ROLE
        │     ├── {SWIMLANE}_{ENV}_WRITE_ROLE
        │     │     └── {SWIMLANE}_{ENV}_READ_ROLE
        │     └── {SWIMLANE}_{ENV}_WRITE_ROLE
        │           └── {SWIMLANE}_{ENV}_READ_ROLE
        ├── {SWIMLANE}_{ENV}_WRITE_ROLE
        │     └── {SWIMLANE}_{ENV}_READ_ROLE
        └── {SWIMLANE}_{ENV}_READ_ROLE
```

### Role Permissions

| Role | Database | Schemas | Tables/Views | Warehouse |
|------|----------|---------|--------------|-----------|
| **READ** | USAGE | USAGE | SELECT | USAGE |
| **WRITE** | USAGE | USAGE + CREATE | SELECT + INSERT/UPDATE/DELETE | USAGE + OPERATE |
| **ADMIN** | USAGE + MODIFY | All WRITE perms | All WRITE perms | USAGE + OPERATE + MODIFY |

## 🔐 Security Best Practices

### Implemented
✅ JWT authentication with RSA keys  
✅ Managed access schemas  
✅ Role hierarchy following Snowflake best practices  
✅ Least privilege access (READ < WRITE < ADMIN)  
✅ Future grants for automatic privilege assignment  
✅ Sensitive outputs marked appropriately  
✅ `.gitignore` configured for state files  

### Recommendations
- [ ] Use remote state backend (S3, Terraform Cloud, etc.)
- [ ] Enable state encryption
- [ ] Rotate RSA keys regularly
- [ ] Set `prevent_destroy = true` on production databases
- [ ] Implement MFA for Snowflake users
- [ ] Use separate Terraform workspaces for environments
- [ ] Store `terraform.tfvars` in secure vault (never commit!)

## 🛠️ Common Operations

### Add a New Swimlane

Edit `variables.tf`:

```hcl
variable "swimlanes" {
  default = {
    master = { ... }
    finance = { ... }
    marketing = { ... }
    sales = {  # New swimlane
      environments = ["prod", "dev"]
      description  = "Sales department swimlane"
    }
  }
}
```

Then run:
```bash
terraform plan
terraform apply
```

### View User Credentials

```bash
# Public keys
terraform output user_public_keys

# Private keys (sensitive)
terraform output -json user_private_keys | jq -r '.finance_analyst' > finance_analyst_key.pem
```

### Connect as Sample User

```bash
snowsql -a <account_name> \
        -u FINANCE_ANALYST_USER \
        --private-key-path finance_analyst_key.pem \
        -r FINANCE_PROD_READ_ROLE \
        -w FINANCE_PROD_WH \
        -d FINANCE_PROD_DB \
        -s ANALYTICS
```

### Destroy Infrastructure

```bash
# Review what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy
```

## 📊 Customization

### Change Warehouse Size

Edit `terraform.tfvars`:
```hcl
warehouse_size = "MEDIUM"  # or LARGE, X-LARGE, etc.
```

### Add Custom Schemas

Edit `swimlanes.tf` or create per-swimlane overrides in the module call:

```hcl
module "swimlanes" {
  # ...
  create_schemas = ["RAW", "STAGING", "ANALYTICS", "ARCHIVE"]
}
```

### Environment-Specific Warehouse Sizes

Modify `swimlanes.tf` to use conditionals:

```hcl
warehouse_size = each.value.environment == "prod" ? "MEDIUM" : "SMALL"
```

## 🐛 Troubleshooting

### Authentication Errors

```
Error: authentication failed
```

**Solution**: Verify RSA key is correctly assigned to service account:
```sql
DESC USER TERRAFORM_SVC;
```

### Permission Denied

```
Error: Insufficient privileges to operate on database
```

**Solution**: Ensure service account has SYSADMIN, USERADMIN, SECURITYADMIN roles:
```sql
SHOW GRANTS TO USER TERRAFORM_SVC;
```

### State Lock Issues

```
Error: Error acquiring the state lock
```

**Solution**: If using remote state with locking, manually unlock:
```bash
terraform force-unlock <LOCK_ID>
```

## 📝 Outputs Reference

| Output | Description |
|--------|-------------|
| `swimlanes` | All swimlane resources (databases, warehouses, roles) |
| `admin_roles` | Map of admin role names per swimlane |
| `user_public_keys` | Public keys for all created users |
| `user_private_keys` | Private keys (sensitive, for authentication) |
| `quick_reference` | Quick reference guide for each environment |

## 🤝 Contributing

To contribute or customize:

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Test with `terraform plan`
5. Submit a pull request

## 📄 License

This project is provided as-is for educational and demonstration purposes.

## 🚀 CI/CD

This project includes complete GitHub Actions CI/CD pipelines:

- **Terraform Plan** - Automatically runs on PRs
- **Terraform Apply** - Automatically deploys on merge to main
- **Security Scanning** - TFSec, Checkov, Gitleaks
- **Code Quality** - TFLint, formatting checks
- **Documentation Validation** - Markdown linting

**Setup Guide**: See [CICD.md](CICD.md) for complete instructions.

## 🔗 Resources

- [Snowflake Terraform Provider Docs](https://registry.terraform.io/providers/Snowflake-Labs/snowflake/latest/docs)
- [Snowflake RBAC Best Practices](https://docs.snowflake.com/en/user-guide/security-access-control-overview)
- [Terraform Module Best Practices](https://developer.hashicorp.com/terraform/language/modules/develop)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## 💡 Architecture Decisions

### Why Swimlanes?
- **Isolation**: Each business unit has dedicated resources
- **Cost Tracking**: Easy to monitor compute costs per department
- **Security**: Data access is restricted by business function
- **Scalability**: Add new departments without affecting existing ones

### Why Separate Prod/Dev?
- **Safe Testing**: Engineers can experiment in dev without affecting production
- **Data Promotion**: Controlled promotion of code/data from dev → prod
- **Cost Efficiency**: Dev warehouses can be smaller and auto-suspend faster

### Why Module-Based?
- **Reusability**: Swimlane module can be reused for any number of environments
- **Maintainability**: Changes to swimlane logic apply everywhere
- **Testability**: Modules can be tested in isolation
- **Readability**: Clean separation of concerns

---

**Questions?** Open an issue or contact your Snowflake administrator.
