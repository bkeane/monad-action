# CONTRACT:

# variable "topology" {
#   description = "topology module"
#   type = object({
#     monad_version = string
#     integration_account_name = string
#     integration_account_id = string
#     integration_account_ecr_region = string
#     integration_account_ecr_paths = set(string)
#     deployment_accounts = map(string)

#     git = object({
#       origin = string
#       repo = string
#       owner = string
#       path = string
#     })

#     oidc = object({
#       subject_claim = string
#       integration_role_name = string
#       integration_role_arn = string
#       deployment_role_name = string
#       deployment_roles_arns = map(string)
#     })

#     resource = object({
#       enable_boundary_policy = bool
#       boundary_policy_name = string
#       image_path_wildcard = string
#       resource_name_wildcard = string
#       resource_path_wildcard = string
#     })

#     action = object({
#       integration = string
#       deployment = string
#     })
#   })
# }

output "integration_account_name" {
    value = var.integration_account_name
}

output "integration_account_id" {
    value = var.integration_account_id
}

output "integration_account_ecr_region" {
    value = var.integration_account_ecr_region
}

output "integration_account_ecr_paths" {
    value = var.integration_account_ecr_paths
}

output "deployment_accounts" {
    value = var.deployment_accounts
}

output "monad_version" {
    value = var.monad_version
}

output "oidc" {
    value = local.oidc
}

output "git" {
    value = local.git
}

output "resource" {
    value = local.resource
}

output "action" {
    value = {
        integration = yamlencode(local.integration_action)
        deployment = yamlencode(local.deployment_action)
    }
}
