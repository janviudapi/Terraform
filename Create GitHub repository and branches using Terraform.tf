terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      #version = "~> 6.0"
    }
  }
}

provider "github" {}

###########################################

variable "repository_name" {
  type        = string
  description = "Name of repository to create in github.com"
  default     = "vcloud-lab.com"
}

###########################################

resource "github_repository" "main" {
  name        = var.repository_name
  description = "Terraform test repository for vcloud-lab.com"
  visibility  = "public"
  auto_init   = true
  gitignore_template = "Terraform"
}

resource "github_branch" "main" {
  repository = github_repository.main.name
  branch     = "main"
}

resource "github_branch_default" "default" {
  repository = github_repository.main.name
  branch     = github_branch.main.branch
}

###########################################

output "remote_url" {
  value       = github_repository.main.http_clone_url
  description = "URL to use when adding remote to local git repo."
}