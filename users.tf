#==============================================================================
# SAMPLE USERS
# Example users for each swimlane with appropriate access
#==============================================================================

# Generate RSA keys for sample users
resource "tls_private_key" "sample_users" {
  for_each = toset([
    "finance_analyst",
    "finance_engineer",
    "marketing_analyst",
    "marketing_engineer",
    "master_admin"
  ])

  algorithm = "RSA"
  rsa_bits  = 2048
}

#------------------------------------------------------------------------------
# FINANCE USERS
#------------------------------------------------------------------------------

resource "snowflake_user" "finance_analyst" {
  provider = snowflake.useradmin

  name              = "FINANCE_ANALYST_USER"
  comment           = "Finance analyst with read access to prod and dev"
  default_warehouse = module.swimlanes["finance_prod"].warehouse_name
  default_role      = module.swimlanes["finance_prod"].read_role_name
  default_namespace = module.swimlanes["finance_prod"].schemas_fully_qualified["ANALYTICS"]
  rsa_public_key    = replace(replace(tls_private_key.sample_users["finance_analyst"].public_key_pem, "-----BEGIN PUBLIC KEY-----\n", ""), "\n-----END PUBLIC KEY-----\n", "")
}

resource "snowflake_grant_account_role" "finance_analyst_prod_read" {
  provider  = snowflake.useradmin
  role_name = module.swimlanes["finance_prod"].read_role_name
  user_name = snowflake_user.finance_analyst.name
}

resource "snowflake_grant_account_role" "finance_analyst_dev_read" {
  provider  = snowflake.useradmin
  role_name = module.swimlanes["finance_dev"].read_role_name
  user_name = snowflake_user.finance_analyst.name
}

resource "snowflake_user" "finance_engineer" {
  provider = snowflake.useradmin

  name              = "FINANCE_ENGINEER_USER"
  comment           = "Finance engineer with write access to dev, read to prod"
  default_warehouse = module.swimlanes["finance_dev"].warehouse_name
  default_role      = module.swimlanes["finance_dev"].write_role_name
  default_namespace = module.swimlanes["finance_dev"].schemas_fully_qualified["STAGING"]
  rsa_public_key    = replace(replace(tls_private_key.sample_users["finance_engineer"].public_key_pem, "-----BEGIN PUBLIC KEY-----\n", ""), "\n-----END PUBLIC KEY-----\n", "")
}

resource "snowflake_grant_account_role" "finance_engineer_dev_write" {
  provider  = snowflake.useradmin
  role_name = module.swimlanes["finance_dev"].write_role_name
  user_name = snowflake_user.finance_engineer.name
}

resource "snowflake_grant_account_role" "finance_engineer_prod_read" {
  provider  = snowflake.useradmin
  role_name = module.swimlanes["finance_prod"].read_role_name
  user_name = snowflake_user.finance_engineer.name
}

#------------------------------------------------------------------------------
# MARKETING USERS
#------------------------------------------------------------------------------

resource "snowflake_user" "marketing_analyst" {
  provider = snowflake.useradmin

  name              = "MARKETING_ANALYST_USER"
  comment           = "Marketing analyst with read access to prod and dev"
  default_warehouse = module.swimlanes["marketing_prod"].warehouse_name
  default_role      = module.swimlanes["marketing_prod"].read_role_name
  default_namespace = module.swimlanes["marketing_prod"].schemas_fully_qualified["ANALYTICS"]
  rsa_public_key    = replace(replace(tls_private_key.sample_users["marketing_analyst"].public_key_pem, "-----BEGIN PUBLIC KEY-----\n", ""), "\n-----END PUBLIC KEY-----\n", "")
}

resource "snowflake_grant_account_role" "marketing_analyst_prod_read" {
  provider  = snowflake.useradmin
  role_name = module.swimlanes["marketing_prod"].read_role_name
  user_name = snowflake_user.marketing_analyst.name
}

resource "snowflake_grant_account_role" "marketing_analyst_dev_read" {
  provider  = snowflake.useradmin
  role_name = module.swimlanes["marketing_dev"].read_role_name
  user_name = snowflake_user.marketing_analyst.name
}

resource "snowflake_user" "marketing_engineer" {
  provider = snowflake.useradmin

  name              = "MARKETING_ENGINEER_USER"
  comment           = "Marketing engineer with write access to dev, read to prod"
  default_warehouse = module.swimlanes["marketing_dev"].warehouse_name
  default_role      = module.swimlanes["marketing_dev"].write_role_name
  default_namespace = module.swimlanes["marketing_dev"].schemas_fully_qualified["STAGING"]
  rsa_public_key    = replace(replace(tls_private_key.sample_users["marketing_engineer"].public_key_pem, "-----BEGIN PUBLIC KEY-----\n", ""), "\n-----END PUBLIC KEY-----\n", "")
}

resource "snowflake_grant_account_role" "marketing_engineer_dev_write" {
  provider  = snowflake.useradmin
  role_name = module.swimlanes["marketing_dev"].write_role_name
  user_name = snowflake_user.marketing_engineer.name
}

resource "snowflake_grant_account_role" "marketing_engineer_prod_read" {
  provider  = snowflake.useradmin
  role_name = module.swimlanes["marketing_prod"].read_role_name
  user_name = snowflake_user.marketing_engineer.name
}

#------------------------------------------------------------------------------
# MASTER ADMIN
#------------------------------------------------------------------------------

resource "snowflake_user" "master_admin" {
  provider = snowflake.useradmin

  name              = "MASTER_ADMIN_USER"
  comment           = "Master admin with full access to master swimlane"
  default_warehouse = module.swimlanes["master_prod"].warehouse_name
  default_role      = snowflake_account_role.admin["master"].name
  default_namespace = module.swimlanes["master_prod"].schemas_fully_qualified["ANALYTICS"]
  rsa_public_key    = replace(replace(tls_private_key.sample_users["master_admin"].public_key_pem, "-----BEGIN PUBLIC KEY-----\n", ""), "\n-----END PUBLIC KEY-----\n", "")
}

resource "snowflake_grant_account_role" "master_admin_role" {
  provider  = snowflake.useradmin
  role_name = snowflake_account_role.admin["master"].name
  user_name = snowflake_user.master_admin.name
}

