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

  releases = {
    for release in var.services.releases : "release-${basename(release["MONAD_IMAGE"])}" => {
      name = "${basename(release["MONAD_IMAGE"])}"
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

  accounts = {
    for account in var.spoke_accounts : account.name => {
      name = account.name
      runs-on = "ubuntu-latest"
      needs   = keys(local.releases)
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
          name = "Checkout"
          uses = "actions/checkout@v4"
          with = {
            fetch-depth = 1
          }
        },
        {
          id = "branch-check"
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
            console.log("pass:", pass);
            core.setOutput("pass", pass);
            core.setOutput("roleArn", roleArn);
            EOT
          }
        }
      ]
    }
  }

  deploy = merge([
    for account, job in local.accounts : {
      for deployment in var.services.deployments : "deploy-${account}-${deployment["MONAD_SERVICE"]}" => {
        name = "${deployment["MONAD_SERVICE"]}"
        needs   = account
        runs-on = "ubuntu-latest"
        if      = "needs.${account}.outputs.pass == true"
        env = deployment
        steps = [
          {
            name = "setup"
            uses = "bkeane/monad-action@main"
            with = {
              version = var.monad_version
              role_arn = "$${{ needs.${account}.outputs.roleArn }}"
              registry_id = "$${{ env.MONAD_REGISTRY_ID }}"
              registry_region = "$${{ env.MONAD_REGISTRY_REGION }}"
            }
          },
          {
            name = "deploy"
            run = "monad deploy"
          }
        ]
      }
    }
  ]...)
}

output "deploy" {
  value = yamlencode(merge(local.workflow_common, {
    name = "Deploy"
    on   = var.deploy_on
    jobs = merge(
      local.releases,
      local.accounts,
      local.deploy
    )
  }))
}
