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

variable "api_gateway_ids" {
  description = "The API Gateway V2 IDs used by the services"
  type = set(string)
}

variable "boundary_policy_document" {
  description = "The boundary policy for created roles (data.aws_iam_policy_document)"
  type = object({
    json = string
    minified_json = string
  })
  default = null
}

variable "oidc_policy_document" {
  description = "Additional policy document for github actions OIDC role (data.aws_iam_policy_document)"
  type = object({
    json = string
    minified_json = string
  })
  default = null
}
