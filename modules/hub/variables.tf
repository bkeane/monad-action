variable "origin" {
  description = "https origin of the github repo"
  type        = string
}

variable "mutable" {
  description = "whether ECR repository image tags are mutable"
  type        = bool
  default     = true
}

variable "spoke_accounts" {
  description = "accounts to deploy given branch match"
  type = set(object({
    name      = string
    id        = string
    branches = optional(set(string), ["*"])
  }))

  validation {
    condition = alltrue([
      for account in var.spoke_accounts :
      can(regex("^\\d{12}$", account.id))
    ])
    error_message = "All spoke account IDs must be 12-digit AWS account IDs"
  }
}

variable "boundary_policy_document" {
  description = "The boundary policy for created roles (data.aws_iam_policy_document)"
  type = object({
    json          = string
    minified_json = string
  })
  default = null
}

variable "monad_version" {
  description = "https://github.com/bkeane/monad/releases"
  type        = string
  default     = "latest"
}

variable "services" {
  description = "monad service definitions"
  default = {
    releases    = []
    deployments = []
  }
  type = object({
    releases    = set(map(string))
    deployments = set(map(string))
  })

  validation {
    condition = alltrue([
      for release in var.services.releases :
      alltrue([
        contains(keys(release), "MONAD_CHDIR"),
        contains(keys(release), "MONAD_IMAGE")
      ])
    ])
    error_message = "All release definitions must contain:\n\tMONAD_CHDIR\n\tMONAD_IMAGE"
  }

  validation {
    condition = alltrue([
      for deployment in var.services.deployments :
      alltrue([
        contains(keys(deployment), "MONAD_CHDIR"),
        contains(keys(deployment), "MONAD_SERVICE"),
        contains(keys(deployment), "MONAD_IMAGE")
      ])
    ])
    error_message = "All deployment definitions must contain:\n\tMONAD_CHDIR\n\tMONAD_SERVICE\n\tMONAD_IMAGE"
  }

  validation {
    condition = length(distinct([
      for deployment in var.services.deployments :
      deployment["MONAD_SERVICE"]
    ])) == length(var.services.deployments)
    error_message = "All deployment definitions must have unique MONAD_SERVICE names"
  }

  validation {
    condition = alltrue([
      for release in var.services.releases :
      anytrue([
        for deployment in var.services.deployments :
        release["MONAD_IMAGE"] == deployment["MONAD_IMAGE"]
      ])
    ])
    error_message = "All release definitions must reference a MONAD_IMAGE defined in deployments"
  }
}

variable "deploy_on" {
  description = "https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#on"
  type        = any
  default = {
    pull_request = {}
    push = {
      branches = ["main"]
    }
  }
}

variable "destroy_on" {
  description = "https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#on"
  type        = any
  default = {
    pull_request_target = {
      types = ["closed"]
    }
  }
}