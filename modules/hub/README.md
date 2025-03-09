

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
| <a name="input_mutable"></a> [mutable](#input\_mutable) | whether ECR repository image tags are mutable | `bool` | `true` | no |
| <a name="input_origin"></a> [origin](#input\_origin) | https origin of the github repo | `string` | n/a | yes |
| <a name="input_services"></a> [services](#input\_services) | service definitions | <pre>map(object({<br/>    compose_args = optional(string, "")<br/>    deploy_args = optional(string, "")<br/>    destroy_args = optional(string, "")<br/>  }))</pre> | `{}` | no |
| <a name="input_spoke_account_ids"></a> [spoke\_account\_ids](#input\_spoke\_account\_ids) | The ECR spoke account IDs | `set(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_deploy"></a> [deploy](#output\_deploy) | n/a |
| <a name="output_destroy"></a> [destroy](#output\_destroy) | n/a |
