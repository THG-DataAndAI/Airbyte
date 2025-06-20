# Airbyte + dbt Integration Guide

## Understanding the Integration

The dbt integration with Airbyte works differently than Airbyte's built-in transformations:

1. **Airbyte's Role**: Extracts data from sources and loads it into the destination (PostgreSQL)
2. **dbt's Role**: Transforms the raw data after Airbyte has loaded it

## Why No "Transformations" Tab?

The "Transformations" tab in Airbyte's UI is specifically for Airbyte's custom SQL transformations feature, not for dbt. With dbt:

- Transformations run **after** Airbyte syncs complete
- dbt operates independently on the data in PostgreSQL
- You manage transformations through dbt, not Airbyte's UI

## How to Use dbt with Airbyte

### 1. Set Up Your Airbyte Connection
1. Create a source (e.g., Shopify)
2. Create a PostgreSQL destination
3. Configure your connection to sync data
4. Run the sync to load raw data into PostgreSQL

### 2. Run dbt Transformations
After Airbyte loads data, run dbt transformations:

```bash
# Option 1: Run manually
./dbt/scripts/run_dbt.sh

# Option 2: Connect to dbt pod and run
kubectl exec -it deployment/dbt-service -n airbyte -- bash
dbt run --profiles-dir /dbt/profiles --project-dir /dbt
```

### 3. View Transformed Data
Your transformed data will be in the `dbt_transforms` schema:

```sql
-- Connect to PostgreSQL
kubectl exec -it deployment/airbyte-db-postgresql -n airbyte -- psql -U airbyte -d airbyte

-- View dbt tables
\dt dbt_transforms.*
```

## Workflow Options

### Option 1: Manual Workflow
1. Run Airbyte sync
2. Wait for completion
3. Run dbt transformations
4. Query transformed data

### Option 2: Scheduled Workflow
Set up a cron job to run dbt after Airbyte syncs:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: dbt-run
  namespace: airbyte
spec:
  schedule: "0 */6 * * *"  # Every 6 hours
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: dbt-run
            image: ghcr.io/dbt-labs/dbt-postgres:1.7.4
            command:
            - dbt
            - run
            - --profiles-dir=/dbt/profiles
            - --project-dir=/dbt
            env:
            - name: DBT_DATABASE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: airbyte-db-secrets
                  key: DATABASE_PASSWORD
          restartPolicy: OnFailure
```

### Option 3: Orchestration with Airflow/Dagster
For production use, consider an orchestrator that:
1. Triggers Airbyte sync via API
2. Waits for sync completion
3. Triggers dbt run
4. Handles error notifications

## Data Flow

```
Source (Shopify) 
    ↓ [Airbyte Extract & Load]
PostgreSQL (public schema - raw data)
    ↓ [dbt Transform]
PostgreSQL (dbt_transforms schema - clean data)
    ↓
Analytics/BI Tools
```

## Accessing Transformed Data

### From BI Tools
Connect your BI tool to PostgreSQL and use the `dbt_transforms` schema:
- Host: airbyte-db-postgresql
- Database: airbyte
- Schema: dbt_transforms
- Tables: dim_users, fact_sync_metrics, etc.

### From Applications
Use the same PostgreSQL connection with the `dbt_transforms` schema.

## Best Practices

1. **Sync Schedule**: Align dbt runs with Airbyte sync schedules
2. **Data Quality**: Use dbt tests to validate transformed data
3. **Documentation**: Generate dbt docs for data lineage
4. **Monitoring**: Check dbt logs for transformation issues

## Troubleshooting

### dbt Models Not Running
```bash
# Check dbt service logs
kubectl logs deployment/dbt-service -n airbyte

# Test dbt connection
kubectl exec deployment/dbt-service -n airbyte -- dbt debug
```

### No Data in dbt Tables
1. Verify Airbyte sync completed successfully
2. Check raw data exists in public schema
3. Review dbt model SQL for errors
4. Run dbt with debug flag: `dbt run --debug`