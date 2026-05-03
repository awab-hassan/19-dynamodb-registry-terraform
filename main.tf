terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "xx-region-1"
}

locals {
  envs = {
    staging    = { name_prefix = "staging", deletion_protection = false }
    production = { name_prefix = "",        deletion_protection = true  }
  }
}

# Entity Relation Table (Graph)
resource "aws_dynamodb_table" "entity_relation_table" {
  for_each = local.envs

  name         = "${each.value.name_prefix}EntityRelation_Table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute { name = "PK";               type = "S" }
  attribute { name = "SK";               type = "S" }
  attribute { name = "ALTPK";            type = "S" }
  attribute { name = "ALTSK";            type = "S" }
  attribute { name = "source_node_id";   type = "S" }
  attribute { name = "target_node_id";   type = "S" }

  global_secondary_index {
    name            = "GSI_AllKey"
    hash_key        = "ALTPK"
    range_key       = "ALTSK"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "source_node_index"
    hash_key        = "source_node_id"
    range_key       = "PK"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "target_node_index"
    hash_key        = "target_node_id"
    range_key       = "PK"
    projection_type = "ALL"
  }

  deletion_protection_enabled = each.value.deletion_protection
  point_in_time_recovery { enabled = true }
  server_side_encryption { enabled = true }

  tags = {
    Environment = each.key
    Project     = "DynamoMonday"
  }
}

# Event Log Table (Ledger/Time-Series)
resource "aws_dynamodb_table" "event_log_table" {
  for_each = local.envs

  name         = "${each.value.name_prefix}EventLog_Table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute { name = "PK";                type = "S" }
  attribute { name = "SK";                type = "S" }
  attribute { name = "ALTPK";             type = "S" }
  attribute { name = "ALTSK";             type = "S" }
  attribute { name = "reference_node_id"; type = "S" }
  attribute { name = "account_id";        type = "S" }
  attribute { name = "GSI_Batch_PK";      type = "S" }
  attribute { name = "event_timestamp";   type = "S" }
  attribute { name = "correlation_id";    type = "S" }

  global_secondary_index {
    name            = "GSI_AllKey"
    hash_key        = "ALTPK"
    range_key       = "ALTSK"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "reference_node_index"
    hash_key        = "reference_node_id"
    range_key       = "PK"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "account_index"
    hash_key        = "account_id"
    range_key       = "PK"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "GSI_Batch_Index"
    hash_key        = "GSI_Batch_PK"
    range_key       = "event_timestamp"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "GSI_correlation_index"
    hash_key        = "correlation_id"
    projection_type = "ALL"
  }

  deletion_protection_enabled = each.value.deletion_protection
  point_in_time_recovery { enabled = true }
  server_side_encryption { enabled = true }

  tags = {
    Environment = each.key
    Project     = "DynamoMonday"
  }
}

# Aggregated Metrics Table (Analytics)
resource "aws_dynamodb_table" "aggregated_metrics_table" {
  for_each = local.envs

  name         = "${each.value.name_prefix}AggregatedMetrics_Table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "dimension_hash"
  range_key    = "period_sort_key"

  attribute { name = "dimension_hash";      type = "S" }
  attribute { name = "period_sort_key";     type = "S" }
  attribute { name = "GSISK_metric_alpha";  type = "S" }
  attribute { name = "GSISK_metric_beta";   type = "S" }
  attribute { name = "GSISK_metric_gamma";  type = "S" }

  global_secondary_index {
    name            = "GSI_metric_alpha_index"
    hash_key        = "dimension_hash"
    range_key       = "GSISK_metric_alpha"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "GSI_metric_beta_index"
    hash_key        = "dimension_hash"
    range_key       = "GSISK_metric_beta"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "GSI_metric_gamma_index"
    hash_key        = "dimension_hash"
    range_key       = "GSISK_metric_gamma"
    projection_type = "ALL"
  }

  deletion_protection_enabled = each.value.deletion_protection
  point_in_time_recovery { enabled = true }
  server_side_encryption { enabled = true }

  tags = {
    Environment = each.key
    Project     = "DynamoMonday"
  }
}
