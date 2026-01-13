#==============================================================================
# ADMIN ROLES
# Admin roles span both prod and dev environments for each swimlane
#==============================================================================

resource "snowflake_account_role" "admin" {
  for_each = var.swimlanes
  provider = snowflake.useradmin

  name    = upper("${each.key}_admin_role")
  comment = "Admin access to ${each.key} swimlane (all environments)"
}

# Grant admin roles to SYSADMIN
resource "snowflake_grant_account_role" "admin_to_sysadmin" {
  for_each = snowflake_account_role.admin
  provider = snowflake.securityadmin

  role_name        = each.value.name
  parent_role_name = "SYSADMIN"
}

# Grant WRITE roles from both prod and dev to ADMIN role
resource "snowflake_grant_account_role" "write_to_admin" {
  for_each = local.swimlane_environments
  provider = snowflake.securityadmin

  role_name        = module.swimlanes[each.key].write_role_name
  parent_role_name = snowflake_account_role.admin[each.value.swimlane].name
}

# Grant MODIFY privileges on warehouses to ADMIN roles
resource "snowflake_grant_privileges_to_account_role" "warehouse_modify_admin" {
  for_each = local.swimlane_environments
  provider = snowflake.securityadmin

  privileges        = ["MODIFY", "MONITOR"]
  account_role_name = snowflake_account_role.admin[each.value.swimlane].name
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = module.swimlanes[each.key].warehouse_name
  }
}

# Grant MODIFY privileges on databases to ADMIN roles
resource "snowflake_grant_privileges_to_account_role" "database_modify_admin" {
  for_each = local.swimlane_environments
  provider = snowflake.securityadmin

  privileges        = ["MODIFY", "MONITOR", "CREATE SCHEMA"]
  account_role_name = snowflake_account_role.admin[each.value.swimlane].name
  on_account_object {
    object_type = "DATABASE"
    object_name = module.swimlanes[each.key].database_name
  }
}

