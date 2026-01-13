#==============================================================================
# SWIMLANE ENVIRONMENTS
# Creates database, warehouse, schemas, and roles for each swimlane/environment
#==============================================================================

module "swimlanes" {
  source   = "./modules/swimlane"
  for_each = local.swimlane_environments

  providers = {
    snowflake.default       = snowflake
    snowflake.useradmin     = snowflake.useradmin
    snowflake.securityadmin = snowflake.securityadmin
  }

  swimlane_name          = each.value.swimlane
  environment            = each.value.environment
  description            = each.value.description
  warehouse_size         = var.warehouse_size
  warehouse_auto_suspend = var.warehouse_auto_suspend
}

