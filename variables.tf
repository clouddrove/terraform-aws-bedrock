# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
variable "label_order" {
  type        = list(string)
  default     = ["name", "environment"]
  description = "Label order, e.g. `name`,`environment`."
}

variable "embedding_model_arn" {
  type    = string
  default = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v1"
}

variable "s3_arn" {
  type        = string
  description = "The ARN of S3 bucket"
  default     = ""
}

variable "knowledgebase_name" {
  type    = string
  default = "test-knowledgebase"
}

variable "datasource_name" {
  type    = string
  default = "test-datasource"
}

variable "cluster_arn" {
  type        = string
  description = "The ARN of RDS cluster"
  default     = ""
}

variable "secret_manager_arn" {
  type        = string
  description = "The ARN of Secret Manager"
  default     = ""
}

variable "bedrock_role_name" {
  type        = string
  description = "Enter bedrock role name"
  default     = "bedrock-test-role"
}

variable "bedrock_model_policy_name" {
  type        = string
  description = "Enter bedrock model invoke policy name"
  default     = "bedrock-invokemodel-policy"
}

variable "bedrock_rds_policy_name" {
  type        = string
  description = "Enter bedrock rds policy name"
  default     = "bedrock-rds-policy"
}

variable "bedrock_s3_policy_name" {
  type        = string
  description = "Enter bedrock S3 policy name"
  default     = "bedrock-s3-policy"
}

variable "bedrock_secretmanager_policy_name" {
  type        = string
  description = "Enter bedrock secretmanager role name"
  default     = "bedrock-secretmanager-policy"
}

variable "guardrails_name" {
  type        = string
  description = "Name of the guardrails"
  default     = ""
}

variable "guardrails_block_input_msg" {
  type        = string
  description = "Enter the message to block the input from user"
  default     = ""
}

variable "guardrails_block_output_msg" {
  type        = string
  description = "Enter the message to block the output from bedrock"
  default     = ""
}

variable "guardrails_description" {
  type        = string
  default     = "Guardrails for clouddrove"
  description = "Enter the description of guardrails"

}

variable "input_strength" {
  description = "The input priority level"
  type        = string
  default     = "MEDIUM"
  validation {
    condition     = contains(["HIGH", "MEDIUM", "LOW"], var.input_strength)
    error_message = "The priority must be either 'high', 'medium', or 'low'."
  }
}

variable "output_strength" {
  description = "The output priority level"
  type        = string
  default     = "MEDIUM"
  validation {
    condition     = contains(["HIGH", "MEDIUM", "LOW"], var.output_strength)
    error_message = "The priority must be either 'high', 'medium', or 'low'."
  }
}

variable "bedrock_role_arn" {
  type        = string
  description = "Enter the Role Arn for the bedrock"
  default     = null
}

variable "word_content" {
  type        = string
  description = "Enter the word to block"
  default     = ""
}

variable "guardrails_creation" {
  type    = bool
  default = false
}

variable "managed_word_lists_config" {
  type        = string
  default     = "PROFANITY"
  description = "The type of word that manage by guardrails"
}

variable "enable" {
  type    = bool
  default = false
}

variable "bedrock_assume_role_policy" {
  type        = any
  default     = null
  description = "Custom Trust Relationship policy for iam role"
}

variable "words_config" {
  type    = any
  default = null

}

variable "pii_entities" {
  type = list(object({
    action = string
    type   = string
  }))
  default = null
  # default = [
  #   {
  #     action = "BLOCK"
  #     type   = "NAME"
  #   }
  #   # {
  #   #   action = "MASK"
  #   #   type   = "EMAIL"
  #   # }
  # ]
}

variable "regexes" {
  type = list(object({
    action      = string
    description = string
    name        = string
    pattern     = string
  }))
  default = null
  # [
  #   {
  #     action      = "BLOCK"
  #     description = "example regex"
  #     name        = "regex_example"
  #     pattern     = "^\\d{3}-\\d{2}-\\d{4}$"
  #   }
  #   # {
  #   #   action      = "MASK"
  #   #   description = "email regex"
  #   #   name        = "regex_email"
  #   #   pattern     = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
  #   # }
  # ]
}

variable "topics" {
  type = list(object({
    name       = string
    examples   = list(string)
    type       = string
    definition = string
  }))
  default = null
  # [
  #   {
  #     name       = "investment_topic"
  #     examples   = ["Where should I invest my money ?"]
  #     type       = "DENY"
  #     definition = "Investment advice refers to inquiries, guidance, or recommendations regarding the management or allocation of funds or assets with the goal of generating returns."
  #   },
  #   {
  #     name       = "legal_topic"
  #     examples   = ["Is this contract legally binding?"]
  #     type       = "DENY"
  #     definition = "Legal advice refers to inquiries or guidance concerning the interpretation or application of the law."
  #   }
  # ]
}

///Changed

variable "guardrails" {
  type = list(object({
    name                      = string
    blocked_input_messaging   = string
    blocked_outputs_messaging = string
    description               = string
    words_config              = optional(list(string), [])

    topics = optional(list(object({
      name       = string
      examples   = list(string)
      type       = optional(string)
      definition = string
    })), [])

    guardrail_filters = list(object({
      type            = string
      input_strength  = string
      output_strength = string
    }))

  }))

  default = null
}
