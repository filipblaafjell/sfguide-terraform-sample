output "database_name" {
  description = "Name of the created database"
  value       = snowflake_database.this.name
}

output "database_id" {
  description = "ID of the created database"
  value       = snowflake_database.this.id
}

output "warehouse_name" {
  description = "Name of the created warehouse"
  value       = snowflake_warehouse.this.name
}

output "warehouse_id" {
  description = "ID of the created warehouse"
  value       = snowflake_warehouse.this.id
}

output "read_role_name" {
  description = "Name of the read role"
  value       = snowflake_account_role.read.name
}

output "write_role_name" {
  description = "Name of the write role"
  value       = snowflake_account_role.write.name
}

output "schema_names" {
  description = "Map of created schema names"
  value       = { for k, v in snowflake_schema.schemas : k => v.name }
}

output "schemas_fully_qualified" {
  description = "Fully qualified schema names"
  value       = { for k, v in snowflake_schema.schemas : k => "${snowflake_database.this.name}.${v.name}" }
}

