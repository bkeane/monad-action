# Monad-Action

A GitHub Action for installing and configuring
[Monad](https://bkeane.github.io/monad/).

## Description

This action automates the installation and configuration of monad in your GitHub
Actions workflow. It provides a simple way to set up monad with customizable
options for version and AWS-related configurations.

## Inputs

| Input                      | Required | Default  | Description                                                                 |
| -------------------------- | -------- | -------- | --------------------------------------------------------------------------- |
| `version`                  | Yes      | `v0.1.6` | The version of monad to install                                             |
| `ecr_registry_id`          | No       | -        | Configure the ECR registry ID that monad will use                           |
| `ecr_registry_region`      | No       | -        | Configure the ECR registry region that monad will use                       |
| `iam_permissions_boundary` | No       | -        | Name of the IAM permissions boundary that monad will apply to managed roles |

## Usage

```yaml
- uses: bkeane/monad-action@v1
  with:
    version: 'v0.1.6' # Optional, defaults to latest major version.
    ecr_registry_id: '123456789012' # Optional, defaults to caller account
    ecr_registry_region: 'us-west-2' # Optional, defaults to caller region
    iam_permissions_boundary: 'MyPermissionsBoundary' # Optional

- shell: bash
  run: |
    monad -h
```

## References

- [monad releases](https://github.com/bkeane/monad/releases)
- [iam assume role action](https://github.com/aws-actions/configure-aws-credentials)
- [ecr login action](https://github.com/aws-actions/amazon-ecr-login)
- [multi-account / multi-role management](https://github.com/bkeane/stage)
