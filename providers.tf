terraform {
  required_version = ">= 1.0"
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.94"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# Default provider using SYSADMIN for infrastructure resources
provider "snowflake" {
  organization_name = var.organization_name
  account_name      = var.account_name
  user              = var.terraform_user
  role              = "SYSADMIN"
  authenticator     = "SNOWFLAKE_JWT"
  private_key       = file(var.private_key_path)
}

# USERADMIN provider for user and role management
provider "snowflake" {
  organization_name = var.organization_name
  account_name      = var.account_name
  user              = var.terraform_user
  role              = "USERADMIN"
  alias             = "useradmin"
  authenticator     = "SNOWFLAKE_JWT"
  private_key       = file(var.private_key_path)
}

# SECURITYADMIN provider for role grants
provider "snowflake" {
  organization_name = var.organization_name
  account_name      = var.account_name
  user              = var.terraform_user
  role              = "SECURITYADMIN"
  alias             = "securityadmin"
  authenticator     = "SNOWFLAKE_JWT"
  private_key       = file(var.private_key_path)
}

