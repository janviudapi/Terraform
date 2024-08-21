variable "justice_leage" {
  type = string
  default = "justice_league"
}

output "superman" {
  value = split(",", var.justice_leage)
}

output "wonder_woman" {
  value = toset([var.justice_leage])
}

output "batman" {
  value = [var.justice_leage]
}

output "dc_to_object_or_string" {
  value = jsonencode(var.justice_leage)
}

#######################

variable "avenger" {
  type = map(string)
  default = {
    "Bruce_Banner" = "Hulk"
    "Wanda_Maximoff" = "Scarlet_Witch"
  }
}

output "avengers_to_list" {
  value = values(var.avenger)
}

output "avengers_to_set" {
  value = toset(values(var.avenger))
}


output "avengers_map_to_object_or_string" {
  value = jsonencode(var.avenger)
}