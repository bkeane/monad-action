locals {
  workflow_common = {
    env = merge({
      MONAD_REGISTRY_ID     = data.aws_caller_identity.current.account_id
      MONAD_REGISTRY_REGION = data.aws_region.current.name
      MONAD_BRANCH          = "$${{ github.head_ref || github.ref_name }}"
      MONAD_SHA             = "$${{ github.event_name == 'pull_request' && github.event.pull_request.head.sha || github.sha }}"
      }, var.boundary_policy_document != null ? { MONAD_BOUNDARY_POLICY = local.boundary_policy_name } : {},
    )
  }

  build = {
    name        = "hub config"
    description = "Composite action to configure environment for build and push to the hub ECR registry"

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
            version         = var.monad_version
            role_arn        = local.oidc_hub_role_arn
            registry_id     = data.aws_caller_identity.current.account_id
            registry_region = data.aws_region.current.name
            setup_docker    = true
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

  gate = {
    for account in var.spoke_accounts : account.name => {
      name    = account.name
      runs-on = var.runs_on
      permissions = {
        id-token = "write"
        contents = "read"
      }
      outputs = {
        pass    = "$${{ steps.branch-check.outputs.pass }}"
        roleArn = "$${{ steps.branch-check.outputs.roleArn }}"
      }
      steps = [
        {
          id   = "branch-check"
          uses = "actions/github-script@v7"
          env = {
            ACCOUNT_BRANCHES = join(",", account.branches)
            ACCOUNT_ROLE_ARN = "arn:aws:iam::${account.id}:role/${local.oidc_spoke_role_name}"
          }
          with = {
            script = <<-EOT
            const branch = process.env.MONAD_BRANCH;
            const accepted = process.env.ACCOUNT_BRANCHES.split(',').map(b => b.trim());
            const pass = accepted.includes("*") || accepted.includes(branch)
            console.log("branch:", branch);
            console.log("accepted:", accepted);
            console.log("deploy:", pass);
            core.setOutput("pass", pass);
            core.setOutput("roleArn", process.env.ACCOUNT_ROLE_ARN);
            EOT
          }
        }
      ]
    }
  }

  deploy = merge([
    for account, job in local.gate : {
      for service in var.services : "deploy-${account}-${service.name}" => {
        if      = "needs.${account}.outputs.pass == 'true'"
        needs   = account
        runs-on = var.runs_on
        name    = "deploy ${service.name}"
        env = {
          MONAD_SERVICE = service.name
        }

        permissions = {
          id-token = "write"
          contents = "read"
        }

        steps = flatten([
          {
            name = "${account} spoke config"
            uses = "bkeane/monad-action@main"
            with = {
              version         = var.monad_version
              role_arn        = "$${{ needs.${account}.outputs.roleArn }}"
              registry_id     = "$${{ env.MONAD_REGISTRY_ID }}"
              registry_region = "$${{ env.MONAD_REGISTRY_REGION }}"
            }
          },
          {
            name = "deploy ${service.name} to ${account}"
            run  = "${service.entrypoint} ${join(" ", service.deploy_cmd)}"
          },
          var.post_deploy_steps
        ])
      }
    }
  ]...)

  destroy = merge([
    for account, job in local.gate : {
      for service in var.services : "destroy-${account}-${service.name}" => {
        if      = "needs.${account}.outputs.pass == 'true'"
        needs   = account
        runs-on = var.runs_on
        name    = "destroy ${service.name}"
        env = {
          MONAD_SERVICE = service.name
        }
        permissions = {
          id-token = "write"
          contents = "read"
        }
        steps = [
          {
            name = "${account} spoke config"
            uses = "bkeane/monad-action@main"
            with = {
              version         = var.monad_version
              role_arn        = "$${{ needs.${account}.outputs.roleArn }}"
              registry_id     = "$${{ env.MONAD_REGISTRY_ID }}"
              registry_region = "$${{ env.MONAD_REGISTRY_REGION }}"
            }
          },
          {
            name = "destroy ${service.name} in ${account}"
            run  = "${service.entrypoint} ${join(" ", service.destroy_cmd)}"
          }
        ]
      }
    }
  ]...)

  untag = {
    runs-on = var.runs_on
    name    = "untag"
    permissions = {
      id-token = "write"
      contents = "read"
    }
    steps = flatten([
      {
        name = "setup"
        uses = "bkeane/monad-action@main"
        with = {
          version         = var.monad_version
          role_arn        = local.oidc_hub_role_arn
          registry_id     = "$${{ env.MONAD_REGISTRY_ID }}"
          registry_region = "$${{ env.MONAD_REGISTRY_REGION }}"
        }
      },
      [
        for image in var.images : {
          name = "untag ${image}"
          run  = "monad ecr untag --image ${image}:$${{env.MONAD_BRANCH}}"
        }
      ]
    ])
  }
}

output "up_shared_workflow" {
  value = yamlencode(merge(local.workflow_common, {
    name = "Up"
    on   = var.deploy_on
    jobs = merge(
      local.gate,
      local.deploy
    )
  }))
}

output "down_shared_workflow" {
  value = yamlencode(merge(local.workflow_common, {
    name = "Down"
    on   = var.destroy_on
    jobs = merge(
      local.gate,
      local.destroy
    )
  }))
}

output "untag_shared_workflow" {
  value = yamlencode(merge(local.workflow_common, {
    name = "Untag"
    on   = var.untag_on
    jobs = {
      untag = local.untag
    }
  }))
}

output "build_composite_action" {
  value = yamlencode(local.build)
}

