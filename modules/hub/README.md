

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_corefunc"></a> [corefunc](#provider\_corefunc) | ~> 1.0 |

## Modules

No modules.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_boundary_policy_document"></a> [boundary\_policy\_document](#input\_boundary\_policy\_document) | The boundary policy for created roles (data.aws\_iam\_policy\_document) | <pre>object({<br/>    json = string<br/>    minified_json = string<br/>  })</pre> | `null` | no |
| <a name="input_deploy_on"></a> [deploy\_on](#input\_deploy\_on) | https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#on | `any` | <pre>{<br/>  "pull_request": {},<br/>  "push": {<br/>    "branches": [<br/>      "main"<br/>    ]<br/>  }<br/>}</pre> | no |
| <a name="input_destroy_on"></a> [destroy\_on](#input\_destroy\_on) | https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#on | `any` | <pre>{<br/>  "pull_request_target": {<br/>    "types": [<br/>      "closed"<br/>    ]<br/>  }<br/>}</pre> | no |
| <a name="input_mutable"></a> [mutable](#input\_mutable) | whether ECR repository image tags are mutable | `bool` | `true` | no |
| <a name="input_origin"></a> [origin](#input\_origin) | https origin of the github repo | `string` | n/a | yes |
| <a name="input_services"></a> [services](#input\_services) | service definitions | <pre>map(object({<br/>    docker_compose_args = optional(string, "--push")<br/>    monad_compose_args = optional(string, "")<br/>    monad_deploy_args = optional(string, "")<br/>    monad_destroy_args = optional(string, "")<br/>  }))</pre> | `{}` | no |
| <a name="input_spoke_account_ids"></a> [spoke\_account\_ids](#input\_spoke\_account\_ids) | The ECR spoke account IDs | `set(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_deploy"></a> [deploy](#output\_deploy) | n/a |
| <a name="output_destroy"></a> [destroy](#output\_destroy) | n/a |
