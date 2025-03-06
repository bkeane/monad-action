

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
| <a name="input_apigatewayv2_ids"></a> [apigatewayv2\_ids](#input\_apigatewayv2\_ids) | The API Gateway V2 IDs used by the services | `set(string)` | n/a | yes |
| <a name="input_create_oidc_provider"></a> [create\_oidc\_provider](#input\_create\_oidc\_provider) | Whether to create the OIDC provider or lookup existing | `bool` | `false` | no |
| <a name="input_ecr_hub_account_id"></a> [ecr\_hub\_account\_id](#input\_ecr\_hub\_account\_id) | The ECR hub account ID | `string` | n/a | yes |
| <a name="input_ecr_hub_account_region"></a> [ecr\_hub\_account\_region](#input\_ecr\_hub\_account\_region) | The ECR hub account region | `string` | `null` | no |
| <a name="input_ecr_spoke_account_ids"></a> [ecr\_spoke\_account\_ids](#input\_ecr\_spoke\_account\_ids) | The ECR spoke account IDs | `set(string)` | n/a | yes |
| <a name="input_eventbridge_names"></a> [eventbridge\_names](#input\_eventbridge\_names) | The EventBridge bus names used by the services | `set(string)` | n/a | yes |
| <a name="input_mutable"></a> [mutable](#input\_mutable) | whether ECR repository image tags are mutable | `bool` | `true` | no |
| <a name="input_origin"></a> [origin](#input\_origin) | https origin of the github repo | `string` | n/a | yes |
| <a name="input_services"></a> [services](#input\_services) | service definitions | <pre>map(object({<br/>    compose_args = optional(string, "")<br/>    deploy_args = optional(string, "")<br/>    destroy_args = optional(string, "--untag")<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_deploy"></a> [deploy](#output\_deploy) | n/a |
| <a name="output_destroy"></a> [destroy](#output\_destroy) | n/a |
