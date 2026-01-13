terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.94"
      configuration_aliases = [
        snowflake.default,
        snowflake.useradmin,
        snowflake.securityadmin
      ]
    }
  }
}

locals {
  db_name = upper("${var.swimlane_name}_${var.environment}_db")
  wh_name = upper("${var.swimlane_name}_${var.environment}_wh")

  read_role_name  = upper("${var.swimlane_name}_${var.environment}_read_role")
  write_role_name = upper("${var.swimlane_name}_${var.environment}_write_role")
}

#==============================================================================
# DATABASE
#==============================================================================

resource "snowflake_database" "this" {
  provider = snowflake.default

  name         = local.db_name
  comment      = "${var.description} - ${var.environment} environment"
  is_transient = false

  lifecycle {
    prevent_destroy = false # Set to true in production
  }
}

#==============================================================================
# SCHEMAS
#==============================================================================

resource "snowflake_schema" "schemas" {
  for_each = toset(var.create_schemas)
  provider = snowflake.default

  name                = upper(each.key)
  database            = snowflake_database.this.name
  comment             = "${each.key} data layer"
  with_managed_access = true
}

#==============================================================================
# WAREHOUSE
#==============================================================================

resource "snowflake_warehouse" "this" {
  provider = snowflake.default

  name                      = local.wh_name
  comment                   = "${var.swimlane_name} ${var.environment} warehouse"
  warehouse_type            = "STANDARD"
  warehouse_size            = var.warehouse_size
  max_cluster_count         = 1
  min_cluster_count         = 1
  auto_suspend              = var.warehouse_auto_suspend
  auto_resume               = true
  enable_query_acceleration = false
  initially_suspended       = true
}

#==============================================================================
# ROLES
#==============================================================================

resource "snowflake_account_role" "read" {
  provider = snowflake.useradmin

  name    = local.read_role_name
  comment = "Read-only access to ${var.swimlane_name} ${var.environment}"
}

resource "snowflake_account_role" "write" {
  provider = snowflake.useradmin

  name    = local.write_role_name
  comment = "Read and write access to ${var.swimlane_name} ${var.environment}"
}

#==============================================================================
# ROLE HIERARCHY
#==============================================================================

# Grant roles to SYSADMIN
resource "snowflake_grant_account_role" "read_to_sysadmin" {
  provider = snowflake.securityadmin

  role_name        = snowflake_account_role.read.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "write_to_sysadmin" {
  provider = snowflake.securityadmin

  role_name        = snowflake_account_role.write.name
  parent_role_name = "SYSADMIN"
}

# Grant READ to WRITE (write inherits read)
resource "snowflake_grant_account_role" "read_to_write" {
  provider = snowflake.securityadmin

  role_name        = snowflake_account_role.read.name
  parent_role_name = snowflake_account_role.write.name
}

#==============================================================================
# DATABASE GRANTS - READ ROLE
#==============================================================================

resource "snowflake_grant_privileges_to_account_role" "db_usage_read" {
  provider = snowflake.securityadmin

  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.read.name
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.this.name
  }
}

#==============================================================================
# SCHEMA GRANTS - READ ROLE
#==============================================================================

resource "snowflake_grant_privileges_to_account_role" "schema_usage_read" {
  for_each = snowflake_schema.schemas
  provider = snowflake.securityadmin

  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.read.name
  on_schema {
    schema_name = "\"${snowflake_database.this.name}\".\"${each.value.name}\""
  }
}

#==============================================================================
# TABLE GRANTS - READ ROLE
#==============================================================================

# Current tables
resource "snowflake_grant_privileges_to_account_role" "tables_select_read" {
  for_each = snowflake_schema.schemas
  provider = snowflake.securityadmin

  privileges        = ["SELECT"]
  account_role_name = snowflake_account_role.read.name
  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_schema          = "\"${snowflake_database.this.name}\".\"${each.value.name}\""
    }
  }
}

# Future tables
resource "snowflake_grant_privileges_to_account_role" "tables_select_future_read" {
  for_each = snowflake_schema.schemas
  provider = snowflake.securityadmin

  privileges        = ["SELECT"]
  account_role_name = snowflake_account_role.read.name
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${snowflake_database.this.name}\".\"${each.value.name}\""
    }
  }
}

#==============================================================================
# VIEW GRANTS - READ ROLE
#==============================================================================

resource "snowflake_grant_privileges_to_account_role" "views_select_read" {
  for_each = snowflake_schema.schemas
  provider = snowflake.securityadmin

  privileges        = ["SELECT"]
  account_role_name = snowflake_account_role.read.name
  on_schema_object {
    all {
      object_type_plural = "VIEWS"
      in_schema          = "\"${snowflake_database.this.name}\".\"${each.value.name}\""
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "views_select_future_read" {
  for_each = snowflake_schema.schemas
  provider = snowflake.securityadmin

  privileges        = ["SELECT"]
  account_role_name = snowflake_account_role.read.name
  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_schema          = "\"${snowflake_database.this.name}\".\"${each.value.name}\""
    }
  }
}

#==============================================================================
# SCHEMA GRANTS - WRITE ROLE
#==============================================================================

resource "snowflake_grant_privileges_to_account_role" "schema_create_write" {
  for_each = snowflake_schema.schemas
  provider = snowflake.securityadmin

  privileges        = ["CREATE TABLE", "CREATE VIEW", "CREATE STAGE", "CREATE FILE FORMAT", "CREATE SEQUENCE", "CREATE FUNCTION", "CREATE PROCEDURE"]
  account_role_name = snowflake_account_role.write.name
  on_schema {
    schema_name = "\"${snowflake_database.this.name}\".\"${each.value.name}\""
  }
}

#==============================================================================
# TABLE GRANTS - WRITE ROLE
#==============================================================================

# Current tables
resource "snowflake_grant_privileges_to_account_role" "tables_write" {
  for_each = snowflake_schema.schemas
  provider = snowflake.securityadmin

  privileges        = ["INSERT", "UPDATE", "DELETE", "TRUNCATE"]
  account_role_name = snowflake_account_role.write.name
  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_schema          = "\"${snowflake_database.this.name}\".\"${each.value.name}\""
    }
  }
}

# Future tables
resource "snowflake_grant_privileges_to_account_role" "tables_write_future" {
  for_each = snowflake_schema.schemas
  provider = snowflake.securityadmin

  privileges        = ["INSERT", "UPDATE", "DELETE", "TRUNCATE"]
  account_role_name = snowflake_account_role.write.name
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${snowflake_database.this.name}\".\"${each.value.name}\""
    }
  }
}

#==============================================================================
# WAREHOUSE GRANTS
#==============================================================================

resource "snowflake_grant_privileges_to_account_role" "warehouse_usage_read" {
  provider = snowflake.securityadmin

  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.read.name
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.this.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "warehouse_usage_write" {
  provider = snowflake.securityadmin

  privileges        = ["USAGE", "OPERATE"]
  account_role_name = snowflake_account_role.write.name
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.this.name
  }
}

