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

  release_images = {
    for release in var.services.releases : "release-${basename(release["MONAD_IMAGE"])}" => {
      name    = "${basename(release["MONAD_IMAGE"])}"
      runs-on = "ubuntu-latest"
      env     = release
      permissions = {
        id-token = "write"
        contents = "read"
      }
      steps = [
        {
          name = "setup"
          id   = "setup"
          uses = "bkeane/monad-action@main"
          with = {
            version             = var.monad_version
            role_arn            = local.oidc_hub_role_arn
            registry_id         = "$${{ env.MONAD_REGISTRY_ID }}"
            registry_region     = "$${{ env.MONAD_REGISTRY_REGION }}"
            configure_for_build = true
          }
        },
        {
          name = "release"
          id   = "release"
          run  = "monad compose | docker compose -f - build --push"
        }
      ]
    }
  }

  deploy_accounts = {
    for account in var.spoke_accounts : account.name => {
      name    = account.name
      runs-on = "ubuntu-latest"
      needs   = keys(local.release_images)
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
          }
          with = {
            script = <<-EOT
            const branch = process.env.MONAD_BRANCH;
            const accepted = process.env.ACCOUNT_BRANCHES.split(',').map(b => b.trim());
            const pass = accepted.includes("*") || accepted.includes(branch)
            const roleArn = "arn:aws:iam::${account.id}:role/${local.oidc_spoke_role_name}"
            console.log("branch:", branch);
            console.log("accepted:", accepted);
            console.log("deploy:", pass);
            core.setOutput("pass", pass);
            core.setOutput("roleArn", roleArn);
            EOT
          }
        }
      ]
    }
  }

  deploy_services = merge([
    for account, job in local.deploy_accounts : {
      for deployment in var.services.deployments : "deploy-${account}-${deployment["MONAD_SERVICE"]}" => {
        name    = "deploy ${deployment["MONAD_SERVICE"]}"
        needs   = account
        runs-on = "ubuntu-latest"
        if      = "needs.${account}.outputs.pass == 'true'"
        permissions = {
          id-token = "write"
          contents = "read"
        }
        env = deployment
        steps = [
          {
            name = "setup"
            uses = "bkeane/monad-action@main"
            with = {
              version         = var.monad_version
              role_arn        = "$${{ needs.${account}.outputs.roleArn }}"
              registry_id     = "$${{ env.MONAD_REGISTRY_ID }}"
              registry_region = "$${{ env.MONAD_REGISTRY_REGION }}"
            }
          },
          {
            name = "deploy"
            run  = "monad deploy"
          }
        ]
      }
    }
  ]...)

  destroy_accounts = {
    for account in var.spoke_accounts : account.name => {
      name    = account.name
      runs-on = "ubuntu-latest"
      needs   = keys(local.release_images)
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
          }
          with = {
            script = <<-EOT
            const branch = process.env.MONAD_BRANCH;
            const accepted = process.env.ACCOUNT_BRANCHES.split(',').map(b => b.trim());
            const pass = accepted.includes("*") || accepted.includes(branch)
            console.log("branch:", branch);
            console.log("accepted:", accepted);
            console.log("destroy:", pass);
            core.setOutput("pass", pass);
            core.setOutput("roleArn", roleArn);
            EOT
          }
        }
      ]
    }
  }

  destroy_services = merge([
    for account, job in local.destroy_accounts : {
      for deployment in var.services.deployments : "destroy-${account}-${deployment["MONAD_SERVICE"]}" => {
        name    = "destroy ${deployment["MONAD_SERVICE"]}"
        needs   = account
        runs-on = "ubuntu-latest"
        if      = "needs.${account}.outputs.pass == 'true'"
        env     = deployment
        permissions = {
          id-token = "write"
          contents = "read"
        }
        steps = [
          {
            name = "setup"
            uses = "bkeane/monad-action@main"
            with = {
              version         = var.monad_version
              role_arn        = "$${{ needs.${account}.outputs.roleArn }}"
              registry_id     = "$${{ env.MONAD_REGISTRY_ID }}"
              registry_region = "$${{ env.MONAD_REGISTRY_REGION }}"
            }
          },
          {
            name = "destroy"
            run  = "monad destroy"
          }
        ]
      }
    }
  ]...)

  untag_images = {
    for release in var.services.releases : "untag-${basename(release["MONAD_IMAGE"])}" => {
      name    = "untag ${basename(release["MONAD_IMAGE"])}"
      needs   = keys(local.destroy_services)
      runs-on = "ubuntu-latest"
      env     = release
      permissions = {
        id-token = "write"
        contents = "read"
      }
      steps = [
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
        {
          name = "destroy"
          run  = "monad destroy"
        }
      ]
    }
  }
}

output "deploy" {
  value = yamlencode(merge(local.workflow_common, {
    name = "Deploy"
    on   = var.deploy_on
    jobs = merge(
      local.release_images,
      local.deploy_accounts,
      local.deploy_services
    )
  }))
}

output "destroy" {
  value = yamlencode(merge(local.workflow_common, {
    name = "Destroy"
    on   = var.destroy_on
    jobs = merge(
      local.destroy_accounts,
      local.destroy_services,
      local.untag_images
    )
  }))
}