# Monad Github Action

This repository is responsible for setting up a CI/CD substrate for monad to publish and deploy services across multiple AWS accounts.

The terraform modules consist of a hub/spoke topology. 
- You place the `hub` terraform module into whichever account hosts your central ECR registry.
- You place the `spoke` terraform module into whichever accounts you wish to deploy services.

When you terraform the `hub` you can pair it with...

```hcl
resource "local_file" "deploy" {
    content  = module.hub.deploy
    filename = "../../../.github/workflows/deploy.yml"
}

resource "local_file" "destroy" {
    content  = module.hub.destroy
    filename = "../../../.github/workflows/destroy.yml"
}
```

...to integrate monad with your github actions workflows.

## Terraform

### OIDC

It is possible you already have an OIDC provider setup in your AWS account for github. If you do not, use this terraform resource to do so.

```hcl
#
# ThumbPrints
#

resource "aws_iam_openid_connect_provider" "github" {
  # https://github.blog/changelog/2023-06-27-github-actions-update-on-oidc-integration-with-aws/
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}
```

### Hub

The `hub` module creates the necessary resources for github actions image publishing and templates out `./.github/workflows/deploy.yaml` and `./.github/workflows/destroy.yaml`. 

See [module docs](./modules/hub) for more details.

### Spoke

The `spoke` module creates the necessary resources for github actions to achieve cross account deployments. 

See [module docs](./modules/spoke) for more details.

## Example

See the `./e2e/terraform` directory in the [monad repository](https://github.com/bkeane/monad/tree/main/e2e/terraform).