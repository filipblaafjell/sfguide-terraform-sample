# Snowflake Swimlane Architecture

## 🏊 Swimlane Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        SNOWFLAKE ACCOUNT                         │
└─────────────────────────────────────────────────────────────────┘
                                 │
            ┌────────────────────┼────────────────────┐
            │                    │                    │
    ┌───────▼────────┐  ┌───────▼────────┐  ┌───────▼────────┐
    │ MASTER SWIMLANE│  │FINANCE SWIMLANE│  │MARKETING SWIM. │
    └───────┬────────┘  └───────┬────────┘  └───────┬────────┘
            │                   │                    │
    ┌───────┴────────┐  ┌───────┴────────┐  ┌───────┴────────┐
    │  PROD  │  DEV  │  │  PROD  │  DEV  │  │  PROD  │  DEV  │
    └────────┴───────┘  └────────┴───────┘  └────────┴───────┘
```

## 📊 Per Environment Resources

Each environment (e.g., `FINANCE_PROD`) contains:

```
FINANCE_PROD Environment
├── Database: FINANCE_PROD_DB
│   ├── Schema: RAW
│   ├── Schema: STAGING
│   └── Schema: ANALYTICS
├── Warehouse: FINANCE_PROD_WH
│   ├── Size: SMALL
│   ├── Auto-suspend: 60s
│   └── Initially suspended: true
└── Roles
    ├── FINANCE_PROD_READ_ROLE
    └── FINANCE_PROD_WRITE_ROLE
```

## 🔐 Role Hierarchy & Inheritance

```
                    ACCOUNTADMIN
                          │
                     SYSADMIN
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
 MASTER_ADMIN_ROLE  FINANCE_ADMIN_ROLE  MARKETING_ADMIN_ROLE
        │                 │                 │
        │       ┌─────────┴─────────┐       │
        │       │                   │       │
        │  FINANCE_PROD      FINANCE_DEV    │
        │       │                   │       │
        │  ┌────┴────┐         ┌────┴────┐  │
        │  │         │         │         │  │
        │ WRITE    READ      WRITE     READ │
        │  ROLE    ROLE      ROLE      ROLE │
        │                                   │
        └───────────────┬───────────────────┘
                        │
            (Same pattern for Master & Marketing)
```

## 👥 User Access Patterns

### Finance Analyst
```
User: FINANCE_ANALYST_USER
├── Default Role: FINANCE_PROD_READ_ROLE
├── Granted Roles:
│   ├── FINANCE_PROD_READ_ROLE  → SELECT on prod data
│   └── FINANCE_DEV_READ_ROLE   → SELECT on dev data
└── Can Access:
    ├── FINANCE_PROD_DB (read-only)
    └── FINANCE_DEV_DB (read-only)
```

### Finance Engineer
```
User: FINANCE_ENGINEER_USER
├── Default Role: FINANCE_DEV_WRITE_ROLE
├── Granted Roles:
│   ├── FINANCE_DEV_WRITE_ROLE  → Full write access to dev
│   └── FINANCE_PROD_READ_ROLE  → Read access to prod
└── Can Access:
    ├── FINANCE_DEV_DB (read/write)
    └── FINANCE_PROD_DB (read-only)
```

### Master Admin
```
User: MASTER_ADMIN_USER
├── Default Role: MASTER_ADMIN_ROLE
├── Granted Roles:
│   └── MASTER_ADMIN_ROLE → Inherits both PROD and DEV WRITE roles
└── Can Access:
    ├── MASTER_PROD_DB (full admin)
    └── MASTER_DEV_DB (full admin)
```

## 🔒 Permission Matrix

| Role | Database | Schema | Tables | Views | Warehouse |
|------|----------|--------|--------|-------|-----------|
| **READ** | USAGE | USAGE | SELECT | SELECT | USAGE |
| **WRITE** (inherits READ) | USAGE | USAGE<br>CREATE TABLE<br>CREATE VIEW<br>CREATE STAGE<br>CREATE FILE FORMAT | SELECT<br>INSERT<br>UPDATE<br>DELETE<br>TRUNCATE | SELECT | USAGE<br>OPERATE |
| **ADMIN** (inherits WRITE) | USAGE<br>MODIFY<br>MONITOR<br>CREATE SCHEMA | All WRITE perms | All WRITE perms | All WRITE perms | USAGE<br>OPERATE<br>MODIFY<br>MONITOR |

## 🔄 Data Flow Pattern

```
┌─────────────────────────────────────────────────────────────┐
│                     TYPICAL DATA FLOW                        │
└─────────────────────────────────────────────────────────────┘

External Source
       │
       ▼
  [RAW Schema]
       │ (Data Engineers with WRITE role)
       ▼
[STAGING Schema]
       │ (Transformations, cleaning, aggregations)
       ▼
[ANALYTICS Schema]
       │
       ▼
   End Users
   (Analysts with READ role)
```

## 🏗️ Module Architecture

```
Root Configuration
│
├── providers.tf         → Snowflake provider configs
├── locals.tf            → Helper variables
├── swimlanes.tf         → Module instantiation
│   │
│   └── Calls module "swimlane" for each environment
│       │
│       └── modules/swimlane/
│           ├── main.tf       → Core resources
│           ├── variables.tf  → Inputs
│           └── outputs.tf    → Exports
│
├── admin_roles.tf       → Cross-environment admin roles
├── users.tf             → Sample user creation
├── variables.tf         → Root inputs
└── outputs.tf           → Final outputs
```

## 🔁 Terraform Dependency Graph

```
variables.tf
    │
    ▼
locals.tf (swimlane_environments map)
    │
    ├──────────────────┐
    │                  │
    ▼                  ▼
swimlanes.tf      admin_roles.tf
    │                  │
    ▼                  │
modules/swimlane/      │
(creates DB, WH,       │
 schemas, roles)       │
    │                  │
    └──────────┬───────┘
               │
               ▼
          users.tf
       (assigns roles)
               │
               ▼
          outputs.tf
```

## 🚀 Scaling Strategy

### Adding a New Department (Swimlane)

**Step 1**: Update `variables.tf`
```hcl
variable "swimlanes" {
  default = {
    # ... existing swimlanes ...
    sales = {
      environments = ["prod", "dev"]
      description  = "Sales department swimlane"
    }
  }
}
```

**Result**: Terraform automatically creates:
- `SALES_PROD_DB` and `SALES_DEV_DB`
- `SALES_PROD_WH` and `SALES_DEV_WH`
- 6 schemas (3 per environment)
- 4 roles (2 per environment)
- 1 admin role spanning both environments

### Adding a New Environment

```hcl
finance = {
  environments = ["prod", "dev", "staging"]  # Added staging
  description  = "Finance department swimlane"
}
```

### Environment-Specific Configuration

For different warehouse sizes per environment:

```hcl
# In swimlanes.tf
warehouse_size = each.value.environment == "prod" ? "MEDIUM" : "SMALL"
```

## 📈 Cost Optimization

### Warehouse Tuning
- **Auto-suspend**: Set to 60 seconds (warehouses sleep when idle)
- **Initially suspended**: Start suspended, wake on first query
- **Size by environment**: 
  - Dev: SMALL (cheapest)
  - Prod: MEDIUM (balanced)
  - Critical: LARGE (as needed)

### Compute Isolation
Each swimlane has dedicated warehouses:
- Prevents finance queries from slowing marketing workloads
- Easy cost attribution per department
- Can scale independently

### Cost Monitoring Query
```sql
-- Run in Snowflake to see costs per warehouse
SELECT 
    warehouse_name,
    SUM(credits_used) as total_credits,
    SUM(credits_used) * 2.5 as estimated_cost_usd  -- adjust rate
FROM snowflake.account_usage.warehouse_metering_history
WHERE start_time >= DATEADD(day, -30, CURRENT_TIMESTAMP())
GROUP BY warehouse_name
ORDER BY total_credits DESC;
```

## 🛡️ Security Architecture

### Authentication
```
Terraform Service Account
    └── RSA Key Pair (JWT)
         ├── Private Key (stored locally, never committed)
         └── Public Key (assigned to Snowflake user)

Sample Users
    └── RSA Key Pairs (generated by Terraform)
         ├── Private Keys (output for user distribution)
         └── Public Keys (assigned to users automatically)
```

### Network Security
- All connections via Snowflake's encrypted endpoints
- No VPC peering required for basic setup
- Can add IP whitelisting at account level
- Can configure private endpoints for enterprise security

### State Security
⚠️ **Important**: State files contain sensitive data
- Use remote backend (S3, Terraform Cloud, Azure Storage)
- Enable encryption at rest
- Enable state locking
- Never commit `.tfstate` files to git

## 📊 Monitoring & Observability

### Query Monitoring
```sql
-- See who's running what
SELECT 
    user_name,
    role_name,
    warehouse_name,
    query_text,
    execution_time
FROM snowflake.account_usage.query_history
WHERE start_time >= DATEADD(hour, -1, CURRENT_TIMESTAMP())
ORDER BY start_time DESC;
```

### Role Usage
```sql
-- Track role adoption
SELECT 
    grantee_name,
    role_name,
    deleted_on
FROM snowflake.account_usage.grants_to_users
WHERE deleted_on IS NULL;
```

### Resource Utilization
```sql
-- Warehouse efficiency
SELECT 
    warehouse_name,
    AVG(avg_running) as avg_running_queries,
    AVG(avg_queued_load) as avg_queue_depth
FROM snowflake.account_usage.warehouse_load_history
WHERE start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
GROUP BY warehouse_name;
```

---

## 🎯 Design Principles

1. **Least Privilege**: Users get minimum required access
2. **Defense in Depth**: Multiple layers of security (auth, RBAC, schemas)
3. **Modularity**: Reusable components for consistency
4. **Scalability**: Easy to add departments without refactoring
5. **Auditability**: Clear role hierarchy and permissions
6. **Cost Efficiency**: Resource isolation enables cost tracking
7. **Developer Experience**: Dev environments for safe experimentation

---

**Last Updated**: 2026-01-13

