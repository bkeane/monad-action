locals {
  workflow_common = {
    env = merge({
      MONAD_REGISTRY_ID     = data.aws_caller_identity.current.account_id
      MONAD_REGISTRY_REGION = data.aws_region.current.name
      MONAD_BRANCH          = "$${{ github.head_ref || github.ref_name }}"
      MONAD_SHA             = "$${{ github.event_name == 'pull_request' && github.event.pull_request.head.sha || github.sha }}"
    }, var.boundary_policy_document != null ? { MONAD_BOUNDARY_POLICY = local.boundary_policy_name } : {})
  }

  job_common = {
    runs-on = "ubuntu-latest"
    permissions = {
      id-token = "write"
      contents = "read"
    }
  }

  publish = [
    for path, service in var.services : {
      name = "Publish ${basename(path)}"
      run  = "${trimspace("monad --chdir ${path} compose ${service.monad_compose_args}")} | docker compose -f - build ${service.docker_compose_args}"
    }
  ]

  deploy = [
    for path, service in var.services : {
      name = "Deploy ${basename(path)}"
      run  = trimspace("monad --chdir ${path} deploy ${service.monad_deploy_args}")
    }
  ]

  destroy = [
    for path, service in var.services : {
      name = "Destroy ${basename(path)}"
      run  = trimspace("monad --chdir ${path} destroy ${service.monad_destroy_args}")
    }
  ]

  untag = [
    for path, service in var.services : {
      name = "Untag ${basename(path)}"
      run  = trimspace("monad --chdir ${path} ecr untag")
    }
  ]
}

output "deploy" {
  value = yamlencode(merge(local.workflow_common, {
    name = "Deploy"

    on = var.deploy_on

    jobs = {
      publish = merge(local.job_common, {
        steps = concat([
          {
            name = "Setup Monad"
            id   = "setup-monad"
            uses = "bkeane/monad-action@main"
            with = {
              version         = "latest"
              role_arn        = local.oidc_hub_role_arn
              registry_id     = "$${{ env.MONAD_REGISTRY_ID }}"
              registry_region = "$${{ env.MONAD_REGISTRY_REGION }}"
              configure_for_build = true
            }
          }
        ], local.publish)
      }),

      deploy = merge(local.job_common, {
        needs = "publish"
        strategy = {
          matrix = {
            role_arn = local.oidc_spoke_role_arns
          }
        }
        steps = concat([
          {
            name = "Setup Monad"
            id   = "setup-monad"
            uses = "bkeane/monad-action@main"
            with = {
              version         = "latest"
              role_arn        = "$${{ matrix.role_arn }}"
              registry_id     = "$${{ env.MONAD_REGISTRY_ID }}"
              registry_region = "$${{ env.MONAD_REGISTRY_REGION }}"
            }
          }
        ], local.deploy)
      })
    }
  }))
}

output "destroy" {
  value = yamlencode(merge(local.workflow_common, {
    name = "Destroy"

    on = var.destroy_on

    jobs = {
      destroy = merge(local.job_common, {
        strategy = {
          matrix = {
            role_arn = local.oidc_spoke_role_arns
          }
        }
        steps = concat([
          {
            name = "Setup Monad"
            id   = "setup-monad"
            uses = "bkeane/monad-action@main"
            with = {
              version         = "latest"
              role_arn        = "$${{ matrix.role_arn }}"
              registry_id     = "$${{ env.MONAD_REGISTRY_ID }}"
              registry_region = "$${{ env.MONAD_REGISTRY_REGION }}"
            }
          }
        ], local.destroy)
      }),
    }

    untag = merge(local.job_common, {
        steps = concat([
          {
            name = "Setup Monad"
            id   = "setup-monad"
            uses = "bkeane/monad-action@main"
            with = {
              version         = "latest"
              role_arn        = local.oidc_hub_role_arn
              registry_id     = "$${{ env.MONAD_REGISTRY_ID }}"
              registry_region = "$${{ env.MONAD_REGISTRY_REGION }}"
            }
          }
        ], local.untag)
      }), 
  }))
}
