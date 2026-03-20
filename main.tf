# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------
locals {
  label_order = var.label_order
}

resource "aws_iam_role" "bedrock_role" {

  count = var.enable ? 1 : 0
  name  = var.bedrock_role_name

  assume_role_policy = var.bedrock_assume_role_policy != null ? var.bedrock_assume_role_policy : jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AmazonBedrockKnowledgeBaseTrustPolicy",
        Effect = "Allow",
        Principal = {
          Service = "bedrock.amazonaws.com"
        },
        Action = "sts:AssumeRole",
      }
    ]
  })
}

resource "aws_iam_policy" "invoke_model_policy" {

  count = var.enable ? 1 : 0
  name  = var.bedrock_model_policy_name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "BedrockInvokeModelStatement",
        Effect = "Allow",
        Action = [
          "bedrock:InvokeModel"
        ],
        Resource = [
          "${var.embedding_model_arn}"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "rds_describe_policy" {
  count = var.enable ? 1 : 0
  name  = var.bedrock_rds_policy_name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "RdsDescribeStatementID",
        Effect = "Allow",
        Action = [
          "rds:DescribeDBClusters"
        ],
        Resource = [
          "${var.cluster_arn}"
        ]
      },
      {
        Sid    = "DataAPIStatementID",
        Effect = "Allow",
        Action = [
          "rds-data:BatchExecuteStatement",
          "rds-data:ExecuteStatement"
        ],
        Resource = [
          "${var.cluster_arn}"
        ]
      }
    ]
  })
}
resource "aws_iam_policy" "secrets_manager_policy" {
  count = var.enable ? 1 : 0
  name  = var.bedrock_secretmanager_policy_name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "SecretsManagerGetStatement",
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = [
          "${var.secret_manager_arn}"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "s3_list_get_object_policy" {
  count = var.enable ? 1 : 0
  name  = var.bedrock_s3_policy_name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "S3ListBucketStatement",
        Effect = "Allow",
        Action = [
          "s3:ListBucket"
        ],
        Resource = [
          "${var.s3_arn}"
        ],
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = [
              "${data.aws_caller_identity.current.account_id}"
            ]
          }
        }
      },
      {
        Sid    = "S3GetObjectStatement",
        Effect = "Allow",
        Action = [
          "s3:GetObject"
        ],
        Resource = [
          "${var.s3_arn}/*"
        ],
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = [
              "${data.aws_caller_identity.current.account_id}"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "attach_invoke_model_policy" {
  count      = var.enable ? 1 : 0
  name       = "attach-invoke-model-policy"
  roles      = [aws_iam_role.bedrock_role[count.index].name]
  policy_arn = aws_iam_policy.invoke_model_policy[count.index].arn
}

resource "aws_iam_policy_attachment" "attach_rds_describe_policy" {
  count      = var.enable ? 1 : 0
  name       = "attach-rds-describe-policy"
  roles      = [aws_iam_role.bedrock_role[count.index].name]
  policy_arn = aws_iam_policy.rds_describe_policy[count.index].arn
}

resource "aws_iam_policy_attachment" "attach_secrets_manager_policy" {
  count      = var.enable ? 1 : 0
  name       = "attach-secrets-manager-policy"
  roles      = [aws_iam_role.bedrock_role[count.index].name]
  policy_arn = aws_iam_policy.secrets_manager_policy[count.index].arn
}

resource "aws_iam_policy_attachment" "attach_s3_list_get_object_policy" {
  count      = var.enable ? 1 : 0
  name       = "attach-s3-list-get-object-policy"
  roles      = [aws_iam_role.bedrock_role[count.index].name]
  policy_arn = aws_iam_policy.s3_list_get_object_policy[count.index].arn
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

resource "aws_bedrockagent_knowledge_base" "knowledge_base" {

  count    = var.enable ? 1 : 0
  name     = var.knowledgebase_name
  role_arn = var.bedrock_role_arn != null ? var.bedrock_role_arn : aws_iam_role.bedrock_role[count.index].arn
  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      embedding_model_arn = var.embedding_model_arn
    }
    type = "VECTOR"
  }

  storage_configuration {
    type = "RDS"
    rds_configuration {
      credentials_secret_arn = var.secret_manager_arn
      database_name          = "postgres"
      field_mapping {
        metadata_field    = "metadata"
        primary_key_field = "id"
        text_field        = "chunks"
        vector_field      = "embedding"

      }
      resource_arn = var.cluster_arn
      table_name   = "bedrock_integration.bedrock_kb"

    }
  }

  depends_on = [
    aws_iam_policy_attachment.attach_invoke_model_policy,
    aws_iam_policy_attachment.attach_rds_describe_policy,
    aws_iam_policy_attachment.attach_secrets_manager_policy,
    aws_iam_policy_attachment.attach_s3_list_get_object_policy,

  ]
}

resource "aws_bedrockagent_data_source" "bedrock" {
  count             = var.enable ? 1 : 0
  knowledge_base_id = aws_bedrockagent_knowledge_base.knowledge_base[count.index].id
  name              = var.datasource_name
  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = var.s3_arn
    }
  }
  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "FIXED_SIZE"
      fixed_size_chunking_configuration {
        max_tokens         = 1536
        overlap_percentage = 20
      }
    }
  }
}

locals {
  guardrails_map = {
    for idx, guardrail in var.guardrails :
    "guardrail_${idx}" => guardrail
  }
}

resource "aws_bedrock_guardrail" "guardrail" {
  for_each                  = local.guardrails_map
  name                      = each.value.name
  blocked_input_messaging   = each.value.blocked_input_messaging
  blocked_outputs_messaging = each.value.blocked_outputs_messaging

  description = each.value.description

  content_policy_config {
    dynamic "filters_config" {
      for_each = each.value.guardrail_filters
      content {
        input_strength  = filters_config.value.input_strength
        output_strength = filters_config.value.output_strength
        type            = filters_config.value.type
      }

    }
  }


  word_policy_config {
    # count= var.enable_words_config ?1:0
    managed_word_lists_config {
      type = "PROFANITY"
    }
    dynamic "words_config" {
      for_each = each.value.words_config
      content {
        text = words_config.value
      }
    }
  }

  topic_policy_config {
    dynamic "topics_config" {
      for_each = length(each.value.topics) > 0 ? each.value.topics : []
      content {
        name       = topics_config.value.name
        examples   = topics_config.value.examples
        type       = topics_config.value.type
        definition = topics_config.value.definition
      }
    }
  }
}
resource "awscc_bedrock_guardrail_version" "llm_response_version" {
  for_each             = local.guardrails_map
  guardrail_identifier = aws_bedrock_guardrail.guardrail[each.key].guardrail_id
  description          = "version1"
}
