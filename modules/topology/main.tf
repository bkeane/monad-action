terraform {
  required_providers {
    corefunc = {
      source  = "northwood-labs/corefunc"
      version = "~> 1.0"
    }
  }
}

locals {
  integration_account_region = var.integration_account_region == "caller region" ? data.aws_region.current.name : var.integration_account_region

  # Git
  git_repo_path       = replace(data.corefunc_url_parse.origin.path, ".git", "")
  git_repo_path_parts = compact(split("/", local.git_repo_path))
  git = {
    origin = var.origin
    repo   = local.git_repo_path_parts[1]
    owner  = local.git_repo_path_parts[0]
    path   = local.git_repo_path
  }

  # OIDC General
  oidc_subject_claim = "repo:${local.git.owner}/${local.git.repo}:*" # wildcard for all branches

  # OIDC Integration Account
  oidc_integration_role_name = "${local.git.repo}-hub-oidc-role"
  oidc_integration_role_arn  = "arn:aws:iam::${var.integration_account_id}:role/${local.oidc_integration_role_name}"

  # OIDC Deployment Accounts
  oidc_deployment_role_name = "${local.git.repo}-spoke-oidc-role"
  odic_deployment_roles_arns = {
    for account, id in var.deployment_accounts : account => "arn:aws:iam::${id}:role/${local.oidc_deployment_role_name}"
  }

  # Other conventions
  resource = {
    integration_account_role_arn = local.oidc_integration_role_arn
    integration_account_role_name = local.oidc_integration_role_name
    deployment_account_role_name = local.oidc_deployment_role_name
    deployment_account_role_arns = local.odic_deployment_roles_arns
    boundary_policy_name   = "${local.git.name}-boundary-policy"
    image_path_wildcard    = "${local.git.owner}/${local.git.name}/*"
    resource_name_wildcard = "${local.git.name}-*"
    resource_path_wildcard = "${local.git.name}/*/*"
  }
}

data "corefunc_url_parse" "origin" {
  url = var.origin
}

data "aws_region" "current" {}
