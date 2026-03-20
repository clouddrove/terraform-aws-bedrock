provider "aws" {
  region = "us-east-1"
}

module "bedrock" {
  source      = "../../"
  name        = "bedrock"
  environment = "test"
}
