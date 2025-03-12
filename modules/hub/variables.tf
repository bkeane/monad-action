variable "origin" {
  description = "https origin of the github repo"
  type = string
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

variable "boundary_policy_document" {
  description = "The boundary policy for created roles (data.aws_iam_policy_document)"
  type = object({
    json = string
    minified_json = string
  })
  default = null
}

variable "services" {
  description = "monad service definitions"
  type = set(map(string))
  default = []

  validation {
    condition = alltrue([
      for service in var.services :
        alltrue([
          contains(keys(service), "MONAD_CHDIR"),
          contains(keys(service), "MONAD_SERVICE"), 
          contains(keys(service), "MONAD_IMAGE")
        ])
    ])
    error_message = "All service definitions must contain:\n\tMONAD_CHDIR\n\tMONAD_SERVICE\n\tMONAD_IMAGE"
  }

  validation {
    condition = length(distinct([
      for service in var.services :
        service.MONAD_SERVICE
    ])) == length(var.services)
    error_message = "Each service definition must have a unique MONAD_SERVICE value"
  }
}

variable "deploy_on" {
  description = "https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#on"
  type = any
  default = {
    pull_request = {}
    push = {
      branches = ["main"]
    }
  }
}

variable "destroy_on" {
  description = "https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#on"
  type = any
  default = {
    pull_request_target = {
      types = ["closed"]
    }
  }
}
