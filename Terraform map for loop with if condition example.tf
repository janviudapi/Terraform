variable "users" {
  type = map(object({
    is_admin = bool
    testattr = string
  }))
  default = {
    "admin_name" = {
      is_admin = true
      testattr = "kiman"
    }
    "regular_name" = {
      is_admin = false
      testattr = "altman"
    }
  }
}

locals {
    admin_users = {
        for name, user in var.users : name => user
        if user.is_admin
    }
    regular_users = {
        for name, user in var.users : name => user
        if !user.is_admin
    }
}

output "admin_users" {
  value = local.admin_users
}

output "regular_users" {
  value = local.regular_users
}