# dbt for Airbyte Data Transformations

This repository contains a standalone dbt project that transforms data loaded by Airbyte into PostgreSQL. It runs in its own Kubernetes namespace (`dbt`) but connects to the Airbyte PostgreSQL database.

## Architecture

- **Namespace**: `dbt` (separate from Airbyte's namespace)
- **Database**: Connects to Airbyte's PostgreSQL instance
- **Schema**: Creates transformed data in `dbt_transforms` schema
- **Deployment**: Runs as CronJob or on-demand Job in Kubernetes

## Prerequisites

- Airbyte deployed and running in `airbyte` namespace
- PostgreSQL accessible from `dbt` namespace
- kubectl configured to access your cluster

## Quick Start

### 1. Deploy dbt via GitHub Actions

1. Push this repository to GitHub
2. Add the required secret to your repository:
   - `GCP_SERVICE_ACCOUNT_KEY`: Same as used for Airbyte
   - `AIRBYTE_DB_PASSWORD`: Same password used for Airbyte's PostgreSQL
3. Go to Actions → "Deploy dbt to GKE"
4. Run workflow with action: `deploy`

### 2. Run Transformations

**Option 1: Via GitHub Actions**
- Go to Actions → "Deploy dbt to GKE"
- Run workflow with action: `run-transformations`

**Option 2: Via kubectl (if you have cluster access)**
```bash
./scripts/run_transformations.sh
```

**Option 3: Automatic**
- Transformations run automatically every 4 hours via CronJob

### 3. View Transformed Data

```bash
# Connect to PostgreSQL
kubectl exec -it deployment/airbyte-db-postgresql -n airbyte -- psql -U airbyte -d airbyte

# Query transformed tables
SELECT * FROM dbt_transforms.dim_users;
```

## Project Structure

```
dbt-repo/
├── README.md
├── dbt_project.yml           # dbt project configuration
├── profiles/
│   └── profiles.yml          # Database connection config
├── models/
│   ├── staging/             # Staging layer (raw data cleanup)
│   │   ├── _sources.yml
│   │   └── stg_*.sql
│   └── marts/               # Business logic layer
│       ├── schema.yml
│       └── dim_*.sql
├── k8s/                     # Kubernetes manifests
│   ├── configmap.yaml       # dbt project files
│   ├── secret.yaml          # Database credentials
│   └── cronjob.yaml         # Scheduled transformations
└── scripts/
    └── run_transformations.sh
```

## GitHub Actions Deployment

### Workflow Actions

The GitHub Actions workflow (`.github/workflows/deploy-dbt.yml`) supports three actions:

1. **deploy**: Deploys dbt to your GKE cluster
2. **run-transformations**: Manually triggers dbt transformations
3. **teardown**: Removes dbt from your cluster

### Required Secrets

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

- `GCP_SERVICE_ACCOUNT_KEY`: The same service account key used for Airbyte deployment
- `AIRBYTE_DB_PASSWORD`: The PostgreSQL password from your Airbyte deployment

### Deployment Process

1. The workflow connects to your existing GKE cluster (same as Airbyte)
2. Creates a separate `dbt` namespace
3. Deploys the CronJob for scheduled transformations
4. Sets up cross-namespace access to Airbyte's PostgreSQL

## Configuration

### Database Connection

The connection to Airbyte's PostgreSQL is configured via environment variables in the Kubernetes deployment:

- `DBT_HOST`: airbyte-db-postgresql.airbyte.svc.cluster.local
- `DBT_PORT`: 5432
- `DBT_DATABASE`: airbyte
- `DBT_USER`: airbyte
- `DBT_PASSWORD`: (from secret)

### Scheduling

By default, transformations run every 4 hours. Modify the schedule in `k8s/cronjob.yaml`:

```yaml
schedule: "0 */4 * * *"  # Every 4 hours
```

## Adding New Models

1. Create new SQL files in `models/staging/` or `models/marts/`
2. Update `models/schema.yml` with documentation
3. Apply the updated ConfigMap:
   ```bash
   kubectl apply -f k8s/configmap.yaml
   ```
4. Run transformations to test

## Monitoring

### View Logs

```bash
# Latest job logs
kubectl logs -n dbt -l job-name --tail=100

# CronJob history
kubectl get jobs -n dbt
```

### dbt Documentation

Generate and serve dbt docs:

```bash
kubectl exec -it deployment/dbt-docs -n dbt -- dbt docs generate
kubectl port-forward -n dbt deployment/dbt-docs 8080:8080
# Open http://localhost:8080
```

## Troubleshooting

### Connection Issues

If dbt cannot connect to PostgreSQL:

1. Check cross-namespace connectivity:
   ```bash
   kubectl run -it --rm debug --image=postgres:13 --restart=Never -n dbt -- \
     psql -h airbyte-db-postgresql.airbyte.svc.cluster.local -U airbyte -d airbyte
   ```

2. Verify NetworkPolicy allows traffic between namespaces

### No Data in Tables

1. Ensure Airbyte has completed at least one sync
2. Check raw tables exist: `\dt public._airbyte_raw_*`
3. Review dbt logs for SQL errors

## Integration with Airbyte Workflow

While this dbt project runs independently, you can coordinate it with Airbyte:

1. **Option 1**: Use Airbyte webhooks to trigger dbt after sync completion
2. **Option 2**: Use an orchestrator (Airflow/Dagster) to coordinate both
3. **Option 3**: Run dbt on a schedule slightly after Airbyte syncs

## License

MIT