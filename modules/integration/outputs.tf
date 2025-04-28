locals {
  integration = {
    name        = "continuous integration"
    description = "Composite action for continuous integration"

    inputs = {}

    runs = {
      using = "composite"
      steps = [
        {
          name = "setup"
          uses = "bkeane/monad-action@main"
          with = {
            version         = var.topology.monad_version
            role_arn        = var.topology.resource.integration_account_role_arn
            registry_id     = var.topology.integration_account_id
            registry_region = var.topology.integration_account_ecr_region
            setup_docker    = true
            checkout        = true
          }
        }
      ]
    }
  }

  deployment = {
    name        = "monad continuous deployment"
    description = "Monad composite action for continuous deployment"

    inputs = {
      account = {
        required = true
        type     = "string"
      }
    }

    outputs = {
      role_arn = {
        description = "The role arn for the given account"
        value = "$${{ steps.validation.outputs.role_arn }}"
      }
    }

    runs = {
      using = "composite"
      steps = [
        {
          name = "validation"
          id   = "validation"
          uses = "actions/github-script@v7"
          env = {
            ACCOUNT_ROLE_ARNS = jsonencode(var.topology.resource.deployment_account_role_arns)
          }
          with = {
            script = <<-EOT
            const account_role_arns = JSON.parse(process.env.ACCOUNT_ROLE_ARNS);
            const given_account = '$${{ inputs.account }}';
            const valid_accounts = Object.keys(account_role_arns).join(', ');
            if (!(given_account in account_role_arns)) {
              console.error('Invalid account name given: ' + given_account);
              console.error('Valid accounts are: ' + valid_accounts);
              core.setFailed('input validation failed');
            }
            core.setOutput('role_arn', account_role_arns[given_account]);
            EOT
          }
        },
        {
          name = "setup"
          uses = "bkeane/monad-action@main"
          with = {
            version         = var.topology.monad_version
            role_arn        = "$${{ steps.validation.outputs.role_arn }}"
            registry_id     = var.topology.integration_account_id
            registry_region = var.topology.integration_account_ecr_region
            setup_docker    = false
            checkout        = true
          }
        }
      ]
    }
  }
}

output "integration_action" {
  value = yamlencode(local.integration)
}

output "deployment_action" {
  value = yamlencode(local.deployment)
}
