variable "swimlane_name" {
  description = "Name of the swimlane (e.g., master, finance, marketing)"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., prod, dev)"
  type        = string
}

variable "description" {
  description = "Description of the swimlane"
  type        = string
}

variable "warehouse_size" {
  description = "Size of the warehouse"
  type        = string
  default     = "SMALL"
}

variable "warehouse_auto_suspend" {
  description = "Auto suspend time in seconds"
  type        = number
  default     = 60
}

variable "create_schemas" {
  description = "List of schemas to create in the database"
  type        = list(string)
  default     = ["RAW", "STAGING", "ANALYTICS"]
}

