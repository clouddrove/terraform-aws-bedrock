## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bedrock\_assume\_role\_policy | Custom Trust Relationship policy for iam role | `any` | `null` | no |
| bedrock\_model\_policy\_name | Enter bedrock model invoke policy name | `string` | `"bedrock-invokemodel-policy"` | no |
| bedrock\_rds\_policy\_name | Enter bedrock rds policy name | `string` | `"bedrock-rds-policy"` | no |
| bedrock\_role\_arn | Enter the Role Arn for the bedrock | `string` | `null` | no |
| bedrock\_role\_name | Enter bedrock role name | `string` | `"bedrock-test-role"` | no |
| bedrock\_s3\_policy\_name | Enter bedrock S3 policy name | `string` | `"bedrock-s3-policy"` | no |
| bedrock\_secretmanager\_policy\_name | Enter bedrock secretmanager role name | `string` | `"bedrock-secretmanager-policy"` | no |
| cluster\_arn | The ARN of RDS cluster | `string` | `""` | no |
| datasource\_name | n/a | `string` | `"test-datasource"` | no |
| embedding\_model\_arn | n/a | `string` | `"arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v1"` | no |
| enable | n/a | `bool` | `false` | no |
| guardrails | n/a | <pre>list(object({<br>    name                      = string<br>    blocked_input_messaging   = string<br>    blocked_outputs_messaging = string<br>    description               = string<br>    words_config              = optional(list(string), [])<br><br>    topics = optional(list(object({<br>      name       = string<br>      examples   = list(string)<br>      type       = optional(string)<br>      definition = string<br>    })), [])<br><br>    guardrail_filters = list(object({<br>      type            = string<br>      input_strength  = string<br>      output_strength = string<br>    }))<br><br>  }))</pre> | `null` | no |
| guardrails\_block\_input\_msg | Enter the message to block the input from user | `string` | `""` | no |
| guardrails\_block\_output\_msg | Enter the message to block the output from bedrock | `string` | `""` | no |
| guardrails\_creation | n/a | `bool` | `false` | no |
| guardrails\_description | Enter the description of guardrails | `string` | `"Guardrails for clouddrove"` | no |
| guardrails\_name | Name of the guardrails | `string` | `""` | no |
| input\_strength | The input priority level | `string` | `"MEDIUM"` | no |
| knowledgebase\_name | n/a | `string` | `"test-knowledgebase"` | no |
| label\_order | Label order, e.g. `name`,`environment`. | `list(string)` | <pre>[<br>  "name",<br>  "environment"<br>]</pre> | no |
| managed\_word\_lists\_config | The type of word that manage by guardrails | `string` | `"PROFANITY"` | no |
| output\_strength | The output priority level | `string` | `"MEDIUM"` | no |
| pii\_entities | n/a | <pre>list(object({<br>    action = string<br>    type   = string<br>  }))</pre> | `null` | no |
| regexes | n/a | <pre>list(object({<br>    action      = string<br>    description = string<br>    name        = string<br>    pattern     = string<br>  }))</pre> | `null` | no |
| s3\_arn | The ARN of S3 bucket | `string` | `""` | no |
| secret\_manager\_arn | The ARN of Secret Manager | `string` | `""` | no |
| topics | n/a | <pre>list(object({<br>    name       = string<br>    examples   = list(string)<br>    type       = string<br>    definition = string<br>  }))</pre> | `null` | no |
| word\_content | Enter the word to block | `string` | `""` | no |
| words\_config | n/a | `any` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| label\_order | Label order. |

