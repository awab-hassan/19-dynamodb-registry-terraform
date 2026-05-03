# Project # 19 - Dynamodb Registry Terraform

This Terraform module provisions a multi-environment DynamoDB setup across three data registries, each with a production and staging pair. It implements targeted data models using optimized partition keys, sort keys, and Global Secondary Indexes (GSIs) designed for graph, ledger, and analytical access patterns. Utilizing on-demand capacity, the architecture balances cost-efficiency with the ability to handle variable workloads. This automated configuration ensures staging environments accurately reflect production, facilitating reliable testing and secure deployments.

## Tables and Indexes

| Table | PK / SK | GSIs |
|---|---|---|
| EntityRelation_Table (+ `_staging`) | `source_node_id` / `target_node_id` | `GSI_AllKey`, `source_node_index`, `target_node_index` |
| EventLog_Table (+ `_staging`) | `account_id` / `event_timestamp` | `GSI_Batch_Index`, `GSI_correlation_index` |
| AggregatedMetrics_Table (+ `_staging`) | `dimension_hash` / `period_sort_key` | `GSI_metric_alpha_index`, `GSI_metric_beta_index`, `GSI_metric_gamma_index` |

**EntityRelation_Table** — models the graph relationships between primary and secondary entities. `source_node_index` lists every target a specific source connects to; `target_node_index` lists every source connected to a target; `GSI_AllKey` provides a full cross-cut for backend auditing.

**EventLog_Table** — immutable time-series ledger. `GSI_Batch_Index` surfaces events grouped by processing batches; `GSI_correlation_index` looks up a specific event flow by its public correlation ID.

**AggregatedMetrics_Table** — precomputed analytics data. Three GSIs rank various platform metrics (Alpha, Beta, and Gamma dimensions) for reporting dashboards and system health monitoring.

## Architecture

```text
Application (Lambda / ECS)
         |
         +---> EntityRelation_Table     (source_node_id + target_node_id, 3 GSIs)
         +---> EventLog_Table           (account_id + event_timestamp, 2 GSIs)
         +---> AggregatedMetrics_Table  (dimension_hash + period_sort_key, 3 GSIs)

Each registry has a _staging counterpart for pre-production testing.
```

## Stack

Terraform 1.x · AWS DynamoDB (on-demand) · ap-northeast-1 (Tokyo)

## Repository Layout

```text
dynamodb-registry-terraform/
├── main-1.tf        # Six aws_dynamodb_table resources with GSIs
├── .gitignore
└── README.md
```

## Deployment

```bash
terraform init
terraform plan
terraform apply
```

## Teardown

```bash
terraform destroy
```

Take a point-in-time backup or export to S3 before destroying. This operation is irreversible.

## Notes

- All tables use `PAY_PER_REQUEST` billing. If traffic patterns stabilize, switching to `PROVISIONED` with autoscaling reduces cost.
- Every write to a base table also writes to all its GSIs. Review GSI usage before adding new indexes.
- The `_staging` suffix on table names keeps staging and production isolated within the same AWS account and Terraform apply.
