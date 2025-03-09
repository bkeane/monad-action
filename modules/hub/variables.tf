variable "origin" {
  description = "https origin of the github repo"
  type = string
}

variable "services" {
  description = "service definitions"
  type = map(object({
    docker_compose_args = optional(string, "--push")
    monad_compose_args = optional(string, "")
    monad_deploy_args = optional(string, "")
    monad_destroy_args = optional(string, "")
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

variable "boundary_policy_document" {
  description = "The boundary policy for created roles (data.aws_iam_policy_document)"
  type = object({
    json = string
    minified_json = string
  })
  default = null
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