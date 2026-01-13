#==============================================================================
# SWIMLANE OUTPUTS
#==============================================================================

output "swimlanes" {
  description = "All swimlane details including databases, warehouses, and roles"
  value = {
    for key, swimlane in module.swimlanes : key => {
      database_name  = swimlane.database_name
      warehouse_name = swimlane.warehouse_name
      read_role      = swimlane.read_role_name
      write_role     = swimlane.write_role_name
      schemas        = swimlane.schemas_fully_qualified
    }
  }
}

output "admin_roles" {
  description = "Admin roles for each swimlane"
  value       = { for k, v in snowflake_account_role.admin : k => v.name }
}

#==============================================================================
# USER CREDENTIALS
#==============================================================================

output "user_public_keys" {
  description = "Public keys for created users"
  value = {
    finance_analyst    = tls_private_key.sample_users["finance_analyst"].public_key_pem
    finance_engineer   = tls_private_key.sample_users["finance_engineer"].public_key_pem
    marketing_analyst  = tls_private_key.sample_users["marketing_analyst"].public_key_pem
    marketing_engineer = tls_private_key.sample_users["marketing_engineer"].public_key_pem
    master_admin       = tls_private_key.sample_users["master_admin"].public_key_pem
  }
}

output "user_private_keys" {
  description = "Private keys for created users (SENSITIVE)"
  sensitive   = true
  value = {
    finance_analyst    = tls_private_key.sample_users["finance_analyst"].private_key_pem
    finance_engineer   = tls_private_key.sample_users["finance_engineer"].private_key_pem
    marketing_analyst  = tls_private_key.sample_users["marketing_analyst"].private_key_pem
    marketing_engineer = tls_private_key.sample_users["marketing_engineer"].private_key_pem
    master_admin       = tls_private_key.sample_users["master_admin"].private_key_pem
  }
}

#==============================================================================
# QUICK REFERENCE
#==============================================================================

output "quick_reference" {
  description = "Quick reference guide for accessing Snowflake"
  value = {
    finance_prod = {
      database  = module.swimlanes["finance_prod"].database_name
      warehouse = module.swimlanes["finance_prod"].warehouse_name
      schemas   = module.swimlanes["finance_prod"].schema_names
    }
    finance_dev = {
      database  = module.swimlanes["finance_dev"].database_name
      warehouse = module.swimlanes["finance_dev"].warehouse_name
      schemas   = module.swimlanes["finance_dev"].schema_names
    }
    marketing_prod = {
      database  = module.swimlanes["marketing_prod"].database_name
      warehouse = module.swimlanes["marketing_prod"].warehouse_name
      schemas   = module.swimlanes["marketing_prod"].schema_names
    }
    marketing_dev = {
      database  = module.swimlanes["marketing_dev"].database_name
      warehouse = module.swimlanes["marketing_dev"].warehouse_name
      schemas   = module.swimlanes["marketing_dev"].schema_names
    }
    master_prod = {
      database  = module.swimlanes["master_prod"].database_name
      warehouse = module.swimlanes["master_prod"].warehouse_name
      schemas   = module.swimlanes["master_prod"].schema_names
    }
    master_dev = {
      database  = module.swimlanes["master_dev"].database_name
      warehouse = module.swimlanes["master_dev"].warehouse_name
      schemas   = module.swimlanes["master_dev"].schema_names
    }
  }
}
