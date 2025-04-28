variable "origin" {
    description = "git origin for resource tagging and description"
    type = string
}

variable "monad_version" {
    description = "monad version"
    type = string
    default = "latest"
}

variable "deployment_accounts" {
    description = "account name => account id"
    type = map(string)

    validation {
        condition = alltrue([
            for id in values(var.deployment_accounts) :
            can(regex("^\\d{12}$", id))
        ])
        error_message = "All deployment account IDs must be 12-digit AWS account IDs"
    }
}

variable "integration_account_name" {
    description = "integration account name"
    type = string
}

variable "integration_account_id" {
    description = "integration account id"
    type = string

    validation {
        condition = can(regex("^\\d{12}$", var.integration_account_id))
        error_message = "Integration account ID must be a 12-digit AWS account ID"
    }
}

variable "integration_account_ecr_region" {
    description = "integration account ECR region"
    type = string
}

variable "integration_account_ecr_paths" {
    description = "image paths for integration account ECR repositories"
    type = set(string)
}

variable "enable_boundary_policy" {
    description = "enable boundary policy"
    type = bool
    default = false
}