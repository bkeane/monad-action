locals {
  action = {
    name        = "continuous integration"
    description = "Composite action for continuous integration"

    inputs = {
      registry_id = {
        required = true
        default  = data.aws_caller_identity.current.account_id
        type     = "string"
      }
      registry_region = {
        required = true
        default  = data.aws_region.current.name
        type     = "string"
      }
      monad_branch = {
        required = false
        default  = "$${{ github.head_ref || github.ref_name }}"
        type     = "string"
      }
      monad_sha = {
        required = false
        default  = "$${{ github.event_name == 'pull_request' && github.event.pull_request.head.sha || github.sha }}"
        type     = "string"
      }
    }

    runs = {
      using = "composite"
      steps = [
        {
          name = "setup"
          uses = "bkeane/monad-action@main"
          with = {
            version         = var.topology.monad_version
            role_arn        = var.topology.integration_role_arn
            registry_id     = var.topology.integration_account_id
            registry_region = data.aws_region.current.name
            setup_docker    = true
            checkout        = true
          }
        },
        {
          name = "export"
          uses = "actions/github-script@v7"
          with = {
            script = <<-EOT
          core.exportVariable('MONAD_REGISTRY_ID', '$${{ inputs.registry_id }}');
          core.exportVariable('MONAD_REGISTRY_REGION', '$${{ inputs.registry_region }}');
          core.exportVariable('MONAD_BRANCH', '$${{ inputs.monad_branch }}');
          core.exportVariable('MONAD_SHA', '$${{ inputs.monad_sha }}');
          EOT
          }
        }
      ]
    }
  }
}

output "action" {
  value = yamlencode(local.action)
}
