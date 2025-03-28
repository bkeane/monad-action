terraform {
  required_providers {
    corefunc = {
      source  = "northwood-labs/corefunc"
      version = "~> 1.0"
    }
  }
}

locals {
  # Git
  repo_path  = replace(data.corefunc_url_parse.origin.path, ".git", "")
  repo_parts = compact(split("/", local.repo_path))
  repo_owner = local.repo_parts[0]
  repo_name  = local.repo_parts[1]

  # OIDC
  oidc_spoke_role_name = "${local.repo_name}-spoke-oidc-role"
  oidc_subject_claim = "repo:${local.repo_owner}/${local.repo_name}:*" # wildcard for all branches
  
  # Resources
  boundary_policy_name = "${local.repo_name}-boundary-policy"
  extension_policy_name = "${local.repo_name}-spoke-extended-policy"
  repository_wildcard = "${local.repo_owner}/${local.repo_name}/*"
  resource_wildcard = "${local.repo_name}-*"
  path_wildcard = "${local.repo_name}/*/*"
  image_wildcard = "${local.repo_owner}/${local.repo_name}/*"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "corefunc_url_parse" "origin" {
  url = var.origin
}
