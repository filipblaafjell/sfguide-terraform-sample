# Create a flat list of all swimlane-environment combinations
locals {
  # Flatten swimlanes and environments into a map
  swimlane_environments = merge([
    for swimlane_name, config in var.swimlanes : {
      for env in config.environments :
      "${swimlane_name}_${env}" => {
        swimlane    = swimlane_name
        environment = env
        description = config.description
      }
    }
  ]...)
}

