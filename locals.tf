# LOCAL VALUES

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # FOR EXPRESSIONS

  uppercase_servers = [
    for server in var.example_servers :
    upper(server)
  ]

  filtered_servers = [
    for server in var.example_servers :
    upper(server)
    if server != "api"
  ]

  server_map = {
    for server in var.example_servers :
    server => upper(server)
  }

  example_instance_type = (
    var.example_environment == "prod"
    ? "t3.small"
    : "t3.micro"
  )

  # FUNCTIONS

  function_list = concat(
    ["web", "api"],
    ["worker", "database"]
  )

  function_tags = merge(
    {
      Environment = "dev"
      Project     = "terraform-lab"
    },
    {
      Owner       = "DevSecOps"
      Environment = "prod"
    }
  )

  function_instance_type = lookup(
    {
      dev  = "t3.micro"
      prod = "t3.small"
    },
    var.example_environment,
    "t3.micro"
  )

  function_unique_services = toset([
    "web",
    "api",
    "web",
    "worker",
    "api"
  ])

  function_config = {
    name = "terraform-lab"
  }

  function_optional_value = try(
    local.function_config.description,
    "fallback"
  )

  function_name = coalesce(
    null,
    "",
    "terraform-lab"
  )


}