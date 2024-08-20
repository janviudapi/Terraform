variable "marvel" {
  type = list(any)
  default = ["IronMan","Thor","Hulk","HawkEye","SpiderMan"]
}

resource "null_resource" "avengers_captainmarvel" {
  for_each = toset(var.marvel)
  provisioner "local-exec" {
    command = "echo ${each.value} is an Avenger!"
  }
}

resource "null_resource" "avengers_blackwidow" {
  for_each = { for avenger in var.marvel : avenger => avenger }
  provisioner "local-exec" {
    command = "echo ${each.value} is an Avenger!"
  }
}

resource "null_resource" "avengers_scarletwitch" {
  count = length(var.marvel)

  provisioner "local-exec" {
    command = "echo ${var.marvel[count.index]} is an Avenger!"
  }
}

output "avengers" {
  value = var.marvel
}

output "avengers_infinity_wars" {
  value = { for avenger in var.marvel : avenger => avenger }
}

output "avengers_endgame" {
  value = toset(var.marvel)
}

output "avengers_secret_wars" {
  value = [ for avenger in var.marvel : avenger ]
}
