terraform {
  required_providers {
    corefunc = {
      source  = "northwood-labs/corefunc"
      version = "~> 1.0"
    }
  }
}

data "aws_region" "current" {}
data "corefunc_url_parse" "origin" {
  url = var.origin
}

locals {
  repo_path = replace(data.corefunc_url_parse.origin.path, ".git", "")
  repo_path_parts = compact(split("/", local.repo_path))
  git = {
    origin = var.origin
    path   = local.repo_path
    repo   = local.repo_path_parts[1]
    owner  = local.repo_path_parts[0]
  }

  integration_role_name = "${local.git.repo}-integration-oidc-role"
  deployment_role_name = "${local.git.repo}-deployment-oidc-role"

  oidc = {
    subject_claim = "repo:${local.git.owner}/${local.git.repo}:*" # wildcard for all branches
    integration_role_name = "${local.git.repo}-integration-oidc-role"
    integration_role_arn  = "arn:aws:iam::${var.integration_account_id}:role/${local.integration_role_name}"
    deployment_role_name = "${local.git.repo}-deployment-oidc-role"
    deployment_roles_arns = {
      for account, id in var.deployment_accounts : account => "arn:aws:iam::${id}:role/${local.deployment_role_name}"
    }
  }

  resource = {
    enable_boundary_policy = var.enable_boundary_policy
    boundary_policy_name   = "${local.git.repo}-boundary-policy"
    image_path_wildcard    = "${local.git.owner}/${local.git.repo}/*"
    resource_name_wildcard = "${local.git.repo}-*"
    resource_path_wildcard = "${local.git.repo}/*/*"
  }
}



