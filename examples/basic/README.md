# terraform-aws-bedrock basic example

This is a basic example of the `terraform-aws-bedrock` module.

## Usage

```hcl
module "bedrock" {
  source      = "clouddrove/bedrock/aws"
  name        = "bedrock"
  environment = "test"
}
```
