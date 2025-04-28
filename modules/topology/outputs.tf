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
#     oidc_subject_claim = string

#     resource = object({
#       integration_account_role_name = string
#       integration_account_role_arn = string
#       deployment_account_role_name = string
#       deployment_account_role_arns = map(string)
#       boundary_policy_name = string
#       image_path_wildcard = string
#       resource_name_wildcard = string
#       resource_path_wildcard = string
#     })
    
#     git = object({
#       origin = string
#       repo = string
#       owner = string
#       path = string
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

output "oidc_subject_claim" {
    value = local.oidc_subject_claim
}

output "git" {
    value = local.git
}

output "resource" {
    value = local.resource
}

output "monad_version" {
    value = var.monad_version
}
