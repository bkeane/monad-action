locals {
  integration_action = {
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
            version         = var.monad_version
            role_arn        = local.oidc.integration_role_arn
            registry_id     = var.integration_account_id
            registry_region = var.integration_account_ecr_region
            setup_docker    = true
            checkout        = true
          }
        }
      ]
    }
  }

  deployment_action = {
    name        = "monad continuous deployment"
    description = "Monad composite action for continuous deployment"

    inputs = {
      account = {
        required = true
        type     = "string"
      }
      boundary_enable = {
        required = false
        type     = "boolean"
        default = local.resource.enable_boundary_policy
      }
      boundary_name = {
        required = false
        type     = "string"
        default = local.resource.boundary_policy_name
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
          env = {
            ACCOUNT_ROLE_ARNS = jsonencode(local.oidc.deployment_roles_arns)
          }
          uses = "actions/github-script@v7"
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
          with = merge({
            version         = var.monad_version
            role_arn        = "$${{ steps.validation.outputs.role_arn }}"
            registry_id     = var.integration_account_id
            registry_region = var.integration_account_ecr_region
            setup_docker    = false
            checkout        = true
          }, var.enable_boundary_policy ? { boundary_policy = local.resource.boundary_policy_name } : {})
        }
      ]
    }
  }
}