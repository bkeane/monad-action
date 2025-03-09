variable "origin" {
  description = "https origin of the github repo"
  type = string
}

variable "api_gateway_ids" {
  description = "The API Gateway V2 IDs used by the services"
  type = set(string)
}

variable "boundary_policy" {
  description = "The boundary policy for created roles (data.aws_iam_policy_document)"
  type = object({
    json = string
    minified_json = string
  })
  default = null
}