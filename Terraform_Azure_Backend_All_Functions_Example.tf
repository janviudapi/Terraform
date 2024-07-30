terraform {
  backend "azurerm" {
    resource_group_name  = "vcloud-lab.com"            # Can be passed via `-backend-config=`"resource_group_name=<resource group name>"` in the `init` command.
    storage_account_name = "vcloudlabtfstate"          # Can be passed via `-backend-config=`"storage_account_name=<storage account name>"` in the `init` command.
    container_name       = "tfstate"                   # Can be passed via `-backend-config=`"container_name=<container name>"` in the `init` command.
    key                  = "example.terraform.tfstate" # Can be passed via `-backend-config=`"key=<blob key name>"` in the `init` command.
    use_azuread_auth     = true                        # Can also be set via `ARM_USE_AZUREAD` environment variable.
  }
}

locals {
  # String Functions
  upper_string   = upper("hello")                # "HELLO"
  lower_string   = lower("HELLO")                # "hello"
  replace_string = replace("hello", "e", "a")    # "hallo"
  substr_string  = substr("hello", 1, 3)         # "ell"
  length_string  = length("hello")               # 5
  format_string  = format("Hello, %s!", "World") # "Hello, World!"

  # Collection Functions
  list         = ["one", "two", "three"]
  length_list  = length(local.list)                 # 3
  merge_map    = merge({ a = 1, b = 2 }, { c = 3 }) # {a = 1, b = 2, c = 3}
  concat_list  = concat(["a", "b"], ["c", "d"])     # ["a", "b", "c", "d"]
  flatten_list = flatten([["a", "b"], ["c", "d"]])  # ["a", "b", "c", "d"]
  sort_list    = sort(["b", "a", "c"])              # ["a", "b", "c"]

  # Numeric Functions
  add_numbers      = 1 + 2        # 3
  subtract_numbers = 5 - 3        # 2
  multiply_numbers = 2 * 3        # 6
  divide_numbers   = 10 / 2       # 5
  min_number       = min(1, 2, 3) # 1
  max_number       = max(1, 2, 3) # 3
  abs_number       = abs(-5)      # 5

  # Logical Functions
  bool_and = true && false # false
  bool_or  = true || false # true
  not_bool = !true         # false

  # Date and Time Functions
  timestamp      = timestamp()                           # Current UTC time in RFC 3339 format
  formatted_date = formatdate("YYYY-MM-DD", timestamp()) # e.g., "2023-07-01"

  # IP Address Functions
  cidr    = "192.168.0.0/16"
  subnet1 = cidrsubnet(local.cidr, 8, 1) // "192.168.1.0/24" #cidrsubnet(prefix, newbits, netnum)
  subnet2 = cidrsubnet(local.cidr, 7, 2) // "192.168.1.0/24" #cidrsubnet(prefix, newbits, netnum)
  host    = cidrhost(local.subnet1, 5)   # "192.168.1.5"

  # Type Conversion Functions
  bool_to_string   = tostring(true)  # "true"
  number_to_string = tostring(123)   # "123"
  string_to_number = tonumber("123") # 123

  # Control Structures and Conditional Functions
  conditional_value = true ? "yes" : "no"              # "yes"
  element_value     = element(["a", "b", "c"], 1)      # "b"
  lookup_value      = lookup({ a = 1, b = 2 }, "b", 0) # 2

  # Validation Functions
  contains_example = contains(["a", "b", "c"], "b") # true

  # Additional Examples
  environment        = upper("dev") # "DEV"
  servers            = ["web1", "web2", "web3"]
  server_count       = length(local.servers) # 3
  server_name_prefix = local.server_count > 2 ? "large-cluster" : "small-cluster"
  server_names       = [for server in local.servers : format("%s-%s", local.server_name_prefix, server)]
  deployment_date    = formatdate("YYYY-MM-DD", timestamp()) # e.g., "2023-07-01"
  network_cidr       = "192.168.0.0/16"
  public_subnet      = cidrsubnet(local.network_cidr, 8, 1) # "192.168.1.0/24"
}

output "functions" {
  value = local.subnet2
}
