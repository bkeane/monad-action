variable "topology" {
  description = "topology module"
  type = object({
    monad_version = string
    integration_account_name = string
    integration_account_id = string
    integration_account_ecr_region = string
    integration_account_ecr_paths = set(string)
    deployment_accounts = map(string)

    git = object({
      origin = string
      repo = string
      owner = string
      path = string
    })

    oidc = object({
      subject_claim = string
      integration_role_name = string
      integration_role_arn = string
      deployment_role_name = string
      deployment_roles_arns = map(string)
    })

    resource = object({
      enable_boundary_policy = bool
      boundary_policy_name = string
      image_path_wildcard = string
      resource_name_wildcard = string
      resource_path_wildcard = string
    })

    action = object({
      integration = string
      deployment = string
    })
  })
}

variable "mutable" {
  description = "whether ECR repository image tags are mutable"
  type        = bool
  default     = true
}

variable "runs_on" {
  description = "name of the github actions runner to use"
  type        = string
  default     = "ubuntu-latest"
}