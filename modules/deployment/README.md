

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
| <a name="input_api_gateway_ids"></a> [api\_gateway\_ids](#input\_api\_gateway\_ids) | The API Gateway V2 IDs used by the services | `set(string)` | n/a | yes |
| <a name="input_boundary_policy_document"></a> [boundary\_policy\_document](#input\_boundary\_policy\_document) | The boundary policy for created roles (data.aws\_iam\_policy\_document) | <pre>object({<br/>    json = string<br/>    minified_json = string<br/>  })</pre> | `null` | no |
| <a name="input_extended_policy_document"></a> [extended\_policy\_document](#input\_extended\_policy\_document) | Additional policy document for github actions OIDC role (data.aws\_iam\_policy\_document) | <pre>object({<br/>    json = string<br/>    minified_json = string<br/>  })</pre> | `null` | no |
| <a name="input_origin"></a> [origin](#input\_origin) | https origin of the github repo | `string` | n/a | yes |

## Outputs

No outputs.
