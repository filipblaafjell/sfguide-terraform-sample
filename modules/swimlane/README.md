# Swimlane Module

This module creates a complete Snowflake swimlane with database, schemas, warehouse, roles, and proper RBAC.

## What's Created

- **Database**: One database per swimlane/environment
- **Schemas**: Configurable schemas (default: RAW, STAGING, ANALYTICS)
- **Warehouse**: One warehouse per swimlane/environment
- **Roles**: 
  - READ role (select-only access)
  - WRITE role (inherits READ + insert/update/delete)
- **Grants**: All necessary privileges for proper access control

## Usage

```hcl
module "finance_prod" {
  source = "./modules/swimlane"

  providers = {
    snowflake.default        = snowflake
    snowflake.useradmin      = snowflake.useradmin
    snowflake.securityadmin  = snowflake.securityadmin
  }

  swimlane_name           = "finance"
  environment             = "prod"
  description             = "Finance department swimlane"
  warehouse_size          = "SMALL"
  warehouse_auto_suspend  = 60
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| swimlane_name | Name of the swimlane | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| description | Description of the swimlane | `string` | n/a | yes |
| warehouse_size | Size of the warehouse | `string` | `"SMALL"` | no |
| warehouse_auto_suspend | Auto suspend time in seconds | `number` | `60` | no |
| create_schemas | List of schemas to create | `list(string)` | `["RAW", "STAGING", "ANALYTICS"]` | no |

## Outputs

| Name | Description |
|------|-------------|
| database_name | Name of the created database |
| warehouse_name | Name of the created warehouse |
| read_role_name | Name of the read role |
| write_role_name | Name of the write role |
| schema_names | Map of created schema names |
| schemas_fully_qualified | Fully qualified schema names |

## Role Hierarchy

```
SYSADMIN
  ├── {SWIMLANE}_{ENV}_WRITE_ROLE
  │     └── {SWIMLANE}_{ENV}_READ_ROLE
  └── {SWIMLANE}_{ENV}_READ_ROLE
```

## Permissions

### READ Role
- USAGE on database
- USAGE on all schemas
- SELECT on all current and future tables
- SELECT on all current and future views
- USAGE on warehouse

### WRITE Role (inherits READ)
- CREATE TABLE, VIEW, STAGE, FILE FORMAT on all schemas
- INSERT, UPDATE, DELETE, TRUNCATE on all current and future tables
- USAGE and OPERATE on warehouse

