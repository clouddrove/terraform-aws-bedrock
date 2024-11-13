# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------
provider "aws" {
  region = local.region
}

locals {
  environment = "test"
  label_order = ["name", "environment"]
  region      = "us-east-1"
  name        = "clouddrove"
}

##-----------------------------------------------------------------------------
## S3
##-----------------------------------------------------------------------------
module "s3_bucket" {
  source      = "clouddrove/s3/aws"
  version     = "2.0.0"
  name        = "clouddrove-secure-bucket"
  environment = local.environment
  label_order = local.label_order
  s3_name     = "cdkc"
  acl         = "private"
  versioning  = true
}

##-----------------------------------------------------------------------------
## A VPC is a virtual network that closely resembles a traditional network that you'd operate in your own data center.
##-----------------------------------------------------------------------------
module "vpc" {
  source      = "clouddrove/vpc/aws"
  version     = "2.0.0"
  name        = local.name
  environment = local.environment
  cidr_block  = "172.16.0.0/16"
}

##------------------------------------------------------------------------------
## A subnet is a range of IP addresses in your VPC.
##------------------------------------------------------------------------------
#tfsec:ignore:aws-ec2-no-excessive-port-access  # All ports are allowed by default but can be changed via variables.
#tfsec:ignore:aws-ec2-no-public-ingress-acl  # Public ingress is allowed from all network but can be restricted by using variables.
module "subnets" {
  source             = "clouddrove/subnet/aws"
  version            = "2.0.1"
  name               = local.name
  environment        = local.environment
  availability_zones = ["us-east-1a", "us-east-1b"]
  vpc_id             = module.vpc.vpc_id
  cidr_block         = module.vpc.vpc_cidr_block
  ipv6_cidr_block    = module.vpc.ipv6_cidr_block
  type               = "public"
  igw_id             = module.vpc.igw_id
}

##-----------------------------------------------------------------------------
## PostgreSQL Serverless
##-----------------------------------------------------------------------------
module "aurora_postgresql" {
  source               = "clouddrove/aurora/aws"
  version              = "2.0.0"
  name                 = "${local.name}-postgres"
  environment          = local.environment
  engine               = "aurora-postgresql"
  engine_mode          = "provisioned"
  engine_version       = "16.1"
  master_username      = "root"
  database_name        = "postgres"
  vpc_id               = module.vpc.vpc_id
  subnets              = module.subnets.public_subnet_id
  sg_ids               = []
  allowed_ports        = [5432]
  allowed_ip           = [module.vpc.vpc_cidr_block]
  enable_http_endpoint = true

  monitoring_interval = 60
  apply_immediately   = true
  skip_final_snapshot = true
  serverlessv2_scaling_configuration = {
    min_capacity = 1
    max_capacity = 10
  }
  instance_class      = "db.serverless"
  publicly_accessible = true
  instances = {
    one = {
    }
  }
}

data "aws_secretsmanager_secret" "secret_manager" {
  arn        = module.aurora_postgresql.cluster_master_user_secret[0].secret_arn
  depends_on = [module.aurora_postgresql]
}

data "aws_secretsmanager_secret_version" "secrets" {
  depends_on = [module.aurora_postgresql]
  secret_id  = data.aws_secretsmanager_secret.secret_manager.id
}

resource "null_resource" "apply_sql_commands" {
  depends_on = [module.aurora_postgresql]
  provisioner "local-exec" {
    command = "psql -h ${module.aurora_postgresql.cluster_endpoint} -U root -d postgres -p 5432 -f \"rds_commands.sql\""

    environment = {
      PGPASSWORD = jsondecode(data.aws_secretsmanager_secret_version.secrets.secret_string)["password"]
    }
  }
}

##-----------------------------------------------------------------------------
## Bedrock
##-----------------------------------------------------------------------------
module "bedrock" {

  enable              = true
  source              = "../.."
  embedding_model_arn = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v1"
  s3_arn              = module.s3_bucket.arn
  cluster_arn         = module.aurora_postgresql.cluster_arn
  secret_manager_arn  = module.aurora_postgresql.cluster_master_user_secret[0].secret_arn
  knowledgebase_name  = "test-knowledgebase"
  datasource_name     = "test-datasource"

  bedrock_role_name                 = "bedrock-test-role"
  bedrock_model_policy_name         = "bedrock-invokemodel-policy"
  bedrock_rds_policy_name           = "bedrock-rds-policy"
  bedrock_s3_policy_name            = "bedrock-s3-policy"
  bedrock_secretmanager_policy_name = "bedrock-secretmanager-policy"

  guardrails = [
    {
      name        = "Guardrail1", blocked_input_messaging = "Your request can't be processed at the moment", blocked_outputs_messaging = "Your request can't be processed at the moment",
      description = "Guardrail for Personal intent", words_config = ["HATE"],
      topics = [{
        name       = "investment_topic"
        examples   = ["Where should I invest my money ?"]
        type       = "DENY"
        definition = "Investment advice refers to inquiries, guidance, or recommendations regarding the management or allocation of funds or assets with the goal of generating returns."
      }],

      guardrail_filters = [
        { type = "SEXUAL", input_strength = "HIGH", output_strength = "HIGH" },
        { type = "VIOLENCE", input_strength = "HIGH", output_strength = "HIGH" },
        { type = "HATE", input_strength = "HIGH", output_strength = "HIGH" },
        { type = "INSULTS", input_strength = "HIGH", output_strength = "HIGH" },
        { type = "MISCONDUCT", input_strength = "HIGH", output_strength = "HIGH" },
        { type = "PROMPT_ATTACK", input_strength = "HIGH", output_strength = "NONE" }
      ]
    }
  ]
}