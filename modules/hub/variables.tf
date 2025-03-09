variable "origin" {
  description = "https origin of the github repo"
  type = string
}

variable "services" {
  description = "service definitions"
  type = map(object({
    build_args = optional(string, "")
    compose_args = optional(string, "")
    deploy_args = optional(string, "")
    destroy_args = optional(string, "")
  }))
  default = {}
}

variable "mutable" {
  description = "whether ECR repository image tags are mutable"
  type = bool
  default = true
}

variable "spoke_account_ids" {
  description = "The ECR spoke account IDs"
  type = set(string)
}

variable "boundary_policy" {
  description = "Apply the boundary policy to created roles"
  type = bool
  default = true
}
