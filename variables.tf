# Snowflake Connection Variables
variable "organization_name" {
  description = "Snowflake organization name"
  type        = string
}

variable "account_name" {
  description = "Snowflake account name"
  type        = string
}

variable "terraform_user" {
  description = "Terraform service account username"
  type        = string
  default     = "TERRAFORM_SVC"
}

variable "private_key_path" {
  description = "Path to Snowflake private key file"
  type        = string
  default     = "~/.ssh/snowflake_tf_snow_key.p8"
}

# Environment Configuration
variable "environment" {
  description = "Environment name (used for tagging)"
  type        = string
  default     = "production"
}

# Warehouse Configuration
variable "warehouse_size" {
  description = "Default warehouse size"
  type        = string
  default     = "SMALL"
}

variable "warehouse_auto_suspend" {
  description = "Warehouse auto suspend time in seconds"
  type        = number
  default     = 60
}

# Swimlane Configuration
variable "swimlanes" {
  description = "Map of swimlanes to create with their environments"
  type = map(object({
    environments = list(string)
    description  = string
  }))
  default = {
    master = {
      environments = ["prod", "dev"]
      description  = "Master swimlane for shared resources"
    }
    finance = {
      environments = ["prod", "dev"]
      description  = "Finance department swimlane"
    }
    marketing = {
      environments = ["prod", "dev"]
      description  = "Marketing department swimlane"
    }
  }
}

