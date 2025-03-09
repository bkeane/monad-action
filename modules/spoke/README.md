

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
| <a name="input_boundary_policy"></a> [boundary\_policy](#input\_boundary\_policy) | The boundary policy ARN (data "aws\_iam\_policy\_document") | <pre>object({<br/>    json = string<br/>    minified_json = string<br/>  })</pre> | `null` | no |
| <a name="input_hub_account_id"></a> [hub\_account\_id](#input\_hub\_account\_id) | The ECR hub account ID | `string` | n/a | yes |
| <a name="input_mutable"></a> [mutable](#input\_mutable) | whether ECR repository image tags are mutable | `bool` | `true` | no |
| <a name="input_origin"></a> [origin](#input\_origin) | https origin of the github repo | `string` | n/a | yes |

## Outputs

No outputs.
