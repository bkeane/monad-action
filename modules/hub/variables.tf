variable "origin" {
  description = "https origin of the github repo"
  type        = string
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

variable "images" {
  description = "monad service image repositories"
  type = set(string)
  default = []
}

variable "services" {
  description = "monad service deployment definitions"
  default = []
  type = set(object({
    name = string
    entrypoint = optional(string, "monad")
    deploy_cmd = optional(list(string), ["deploy"])
    destroy_cmd = optional(list(string), ["destroy"])
  }))
}

variable "post_deploy_steps" {
  description = "append steps to deployment jobs"
  type = list(any)
  default = []
}

variable "deploy_on" {
  description = "https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#on"
  type        = any
  default = {
    workflow_call = {}
  }
}

variable "destroy_on" {
  description = "https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#on"
  type        = any
  default = {
    workflow_call = {}
  }
}

variable "untag_on" {
  description = "https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#on"
  type        = any
  default = {
    workflow_call = {}
  }
}

variable "build_on" {
  description = "https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#on"
  type        = any
  default = {
    workflow_call = {}
  }
}
