# dbt Configuration for Airbyte

This directory contains all dbt-related configuration files and models for transforming data loaded by Airbyte.

## Directory Structure

```
dbt-config/
├── README.md                 # This file
├── dbt_project.yml          # Main dbt project configuration
├── profiles/                # Database connection profiles
│   └── profiles.yml
├── models/                  # dbt models
│   ├── staging/            # Staging layer - raw data preparation
│   │   ├── _sources.yml    # Source definitions
│   │   ├── stg_raw_data.sql
│   │   ├── stg_shopify_customers.sql
│   │   └── stg_shopify_orders.sql
│   └── marts/              # Business logic layer
│       ├── schema.yml      # Model tests and documentation
│       ├── dim_users.sql
│       ├── dim_customers.sql
│       └── fact_sync_metrics.sql
└── k8s/                    # Kubernetes configurations
    └── dbt-cronjob.yaml    # CronJob for scheduled transformations
```

## Workflows

The dbt transformations can be executed through GitHub Actions workflows located in `.github/workflows/`:

### dbt-workflow.yml

This workflow provides multiple options for running dbt transformations:

1. **Manual Trigger**: Run transformations on-demand via GitHub Actions UI
2. **Scheduled Runs**: Automatically runs every 4 hours
3. **Actions Available**:
   - `run`: Execute dbt models only
   - `test`: Run dbt tests only
   - `run-and-test`: Execute models and run tests
   - `deploy-cronjob`: Deploy the Kubernetes CronJob for scheduled runs
   - `manual-job`: Run a one-time job in Kubernetes

### Environment Variables

The following environment variables are used by dbt:

- `DBT_DATABASE_HOST`: PostgreSQL host (default: airbyte-db-postgresql)
- `DBT_DATABASE_USER`: Database user (default: airbyte)
- `DBT_DATABASE_PASSWORD`: Database password (from Kubernetes secret)
- `DBT_DATABASE_PORT`: Database port (default: 5432)
- `DBT_DATABASE_NAME`: Database name (default: airbyte)
- `DBT_SCHEMA`: Target schema for transformations (default: dbt_transforms)

## Running dbt Locally

To run dbt transformations locally:

1. Install dbt-postgres:
   ```bash
   pip install dbt-postgres
   ```

2. Set environment variables:
   ```bash
   export DBT_DATABASE_HOST=your-postgres-host
   export DBT_DATABASE_PASSWORD=your-password
   ```

3. Run dbt commands:
   ```bash
   cd dbt-config
   dbt run --profiles-dir=profiles --project-dir=.
   dbt test --profiles-dir=profiles --project-dir=.
   ```

## Models Overview

### Staging Layer
- **stg_raw_data**: Parses JSON data from Airbyte's raw user tables
- **stg_shopify_customers**: Extracts customer data from Shopify
- **stg_shopify_orders**: Extracts order data from Shopify

### Marts Layer
- **dim_users**: Cleaned user dimension with data quality checks
- **dim_customers**: Customer dimension with order metrics and status
- **fact_sync_metrics**: Daily metrics about Airbyte sync performance

## Deployment

The dbt transformations are deployed as Kubernetes Jobs/CronJobs in the same cluster as Airbyte. The workflow automatically:

1. Creates ConfigMaps from the dbt configuration files
2. Deploys Jobs that mount these ConfigMaps
3. Runs transformations using the dbt-postgres Docker image
4. Logs results for monitoring

## Adding New Models

1. Create new SQL files in the appropriate directory (staging/ or marts/)
2. Update `_sources.yml` if adding new source tables
3. Update `schema.yml` to add tests and documentation
4. Commit changes and run the GitHub Actions workflow

## Monitoring

- View transformation logs in GitHub Actions
- Check Kubernetes pod logs: `kubectl logs -n airbyte job/dbt-run-*`
- Query the `dbt_transforms` schema to verify results