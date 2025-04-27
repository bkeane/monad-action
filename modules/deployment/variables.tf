variable "topology" {
  description = "topology module"
  type = object({
    monad_version = string
    integration_account_name = string
    integration_account_id = string
    integration_account_region = string
    integration_account_images = set(string)
    deployment_accounts = map(string)

    resource = object({
      integration_account_role_name = string
      integration_account_role_arn = string
      deployment_account_role_name = string
      deployment_account_role_arns = map(string)
      boundary_policy_name = string
      image_path_wildcard = string
      resource_name_wildcard = string
      resource_path_wildcard = string
    })
    
    git = object({
      origin = string
      name = string
      owner = string
      path = string
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

variable "extended_policy_document" {
  description = "Additional policy document for github actions OIDC role (data.aws_iam_policy_document)"
  type = object({
    json = string
    minified_json = string
  })
  default = null
}
