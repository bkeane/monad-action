

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
| <a name="input_boundary_policy_document"></a> [boundary\_policy\_document](#input\_boundary\_policy\_document) | The boundary policy for created roles (data.aws\_iam\_policy\_document) | <pre>object({<br/>    json          = string<br/>    minified_json = string<br/>  })</pre> | `null` | no |
| <a name="input_build_on"></a> [build\_on](#input\_build\_on) | https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#on | `any` | <pre>{<br/>  "workflow_call": {}<br/>}</pre> | no |
| <a name="input_deploy_on"></a> [deploy\_on](#input\_deploy\_on) | https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#on | `any` | <pre>{<br/>  "workflow_call": {}<br/>}</pre> | no |
| <a name="input_destroy_on"></a> [destroy\_on](#input\_destroy\_on) | https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#on | `any` | <pre>{<br/>  "workflow_call": {}<br/>}</pre> | no |
| <a name="input_images"></a> [images](#input\_images) | monad service image repositories | `set(string)` | `[]` | no |
| <a name="input_monad_version"></a> [monad\_version](#input\_monad\_version) | https://github.com/bkeane/monad/releases | `string` | `"latest"` | no |
| <a name="input_mutable"></a> [mutable](#input\_mutable) | whether ECR repository image tags are mutable | `bool` | `true` | no |
| <a name="input_origin"></a> [origin](#input\_origin) | https origin of the github repo | `string` | n/a | yes |
| <a name="input_post_deploy_steps"></a> [post\_deploy\_steps](#input\_post\_deploy\_steps) | append steps to deployment jobs | `list(any)` | `[]` | no |
| <a name="input_runs_on"></a> [runs\_on](#input\_runs\_on) | name of the github actions runner to use | `string` | `"ubuntu-latest"` | no |
| <a name="input_services"></a> [services](#input\_services) | monad service deployment definitions | <pre>set(object({<br/>    name = string<br/>    entrypoint = optional(string, "monad")<br/>    deploy_cmd = optional(list(string), ["deploy"])<br/>    destroy_cmd = optional(list(string), ["destroy"])<br/>  }))</pre> | `[]` | no |
| <a name="input_setup_docker"></a> [setup\_docker](#input\_setup\_docker) | configure for build time | `bool` | `true` | no |
| <a name="input_spoke_accounts"></a> [spoke\_accounts](#input\_spoke\_accounts) | accounts to deploy given branch match | <pre>set(object({<br/>    name      = string<br/>    id        = string<br/>    branches = optional(set(string), ["*"])<br/>  }))</pre> | n/a | yes |
| <a name="input_untag_on"></a> [untag\_on](#input\_untag\_on) | https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#on | `any` | <pre>{<br/>  "workflow_call": {}<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_build"></a> [build](#output\_build) | n/a |
| <a name="output_down"></a> [down](#output\_down) | n/a |
| <a name="output_untag"></a> [untag](#output\_untag) | n/a |
| <a name="output_up"></a> [up](#output\_up) | n/a |
