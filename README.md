# Airbyte with dbt Integration

This repository contains a complete setup for deploying Airbyte with dbt (Data Build Tool) integration on Google Kubernetes Engine (GKE).

## Architecture

The setup includes:
- **Airbyte**: Data integration platform for ELT pipelines
- **dbt**: Data transformation tool running as a separate service
- **PostgreSQL**: Shared database for both Airbyte metadata and dbt transformations
- **Kubernetes**: Container orchestration on GKE

## Components

### Airbyte
- Deployed via Helm chart
- Uses external PostgreSQL database
- Configured to work with dbt for transformations
- Accessible at `https://airbyte.thg-reporting.com`

### dbt Service
- Custom Docker container with dbt-core and dbt-postgres
- Deployed as a Kubernetes service
- Connected to the same PostgreSQL instance as Airbyte
- Uses `dbt_transforms` schema for transformations

### Database Setup
- PostgreSQL deployed via Bitnami Helm chart
- Separate schemas:
  - `public`: Airbyte metadata and raw data
  - `dbt_transforms`: dbt models and transformations

## Deployment

### Prerequisites
1. GCP project with required APIs enabled
2. GitHub secrets configured:
   - `GCP_SERVICE_ACCOUNT_KEY`
   - `AIRBYTE_DB_PASSWORD`
   - `LETSENCRYPT_EMAIL`
   - DNS provider secrets (optional)

### Deploy via GitHub Actions
1. Go to Actions tab in your repository
2. Run "Deploy Airbyte to GKE" workflow
3. Choose "deploy" action
4. Wait for deployment to complete

### Manual Deployment
```bash
# Set your project ID
export PROJECT_ID=thg-dev-icehouse
export CLUSTER_NAME=airbyte-cluster
export REGION=europe-west2

# Deploy infrastructure
gcloud container clusters create $CLUSTER_NAME --region=$REGION
kubectl create namespace airbyte

# Deploy PostgreSQL
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install airbyte-db bitnami/postgresql --namespace=airbyte

# Deploy Airbyte
helm repo add airbyte https://airbytehq.github.io/helm-charts
helm install airbyte airbyte/airbyte --namespace=airbyte --values values.yaml

# Deploy dbt CronJob
kubectl apply -f dbt-config/k8s/dbt-cronjob.yaml
```

## dbt Configuration

### New Consolidated Structure
All dbt-related files are now organized in the `dbt-config/` directory:

```
dbt-config/
├── README.md                 # dbt-specific documentation
├── dbt_project.yml          # Main dbt project configuration
├── profiles/                # Database connection profiles
│   └── profiles.yml
├── models/                  # dbt models
│   ├── staging/            # Staging layer - raw data preparation
│   │   ├── _sources.yml
│   │   ├── stg_raw_data.sql
│   │   ├── stg_shopify_customers.sql
│   │   └── stg_shopify_orders.sql
│   └── marts/              # Business logic layer
│       ├── schema.yml
│       ├── dim_users.sql
│       ├── dim_customers.sql
│       └── fact_sync_metrics.sql
├── k8s/                    # Kubernetes configurations
│   └── dbt-cronjob.yaml
└── run-dbt-local.sh        # Local development script
```

### Running dbt Transformations

#### Via GitHub Actions Workflow
The dbt transformations can be triggered through the dedicated workflow:
1. Go to Actions tab → "Run dbt Transformations"
2. Choose action: `run`, `test`, `run-and-test`, or `deploy-cronjob`
3. Select environment: `dev` or `prod`
4. Optionally specify models to run

#### Via Local Script
```bash
# Make script executable
chmod +x dbt-config/run-dbt-local.sh

# Run the interactive script
./dbt-config/run-dbt-local.sh
```

#### Manual Kubernetes Execution
```bash
# Create a one-time job from the workflow
gh workflow run dbt-workflow.yml -f action=run -f environment=prod

# Or use kubectl directly
kubectl create job --from=cronjob/dbt-transformation-job dbt-manual-$(date +%s) -n airbyte
```

## Configuration

### Environment Variables
The dbt service uses these environment variables:
- `DBT_DATABASE_HOST`: PostgreSQL host (default: airbyte-db-postgresql)
- `DBT_DATABASE_USER`: Database user (default: airbyte)
- `DBT_DATABASE_PASSWORD`: Database password (from secret)
- `DBT_DATABASE_PORT`: Database port (default: 5432)
- `DBT_DATABASE_NAME`: Database name (default: airbyte)
- `DBT_SCHEMA`: dbt schema (default: dbt_transforms)

### Airbyte Configuration
The `values.yaml` file configures:
- External PostgreSQL connection
- dbt service integration
- Ingress with TLS
- Resource limits and autoscaling

## Usage

### Setting up Data Pipelines
1. Access Airbyte UI at `https://airbyte.thg-reporting.com`
2. Configure source connectors
3. Configure destination (PostgreSQL)
4. Set up connections with sync schedules
5. Data will be available in raw tables for dbt transformations

### dbt Transformations
1. Raw data lands in Airbyte tables (prefixed with `_airbyte_raw_`)
2. dbt staging models clean and structure the data
3. dbt mart models create business-ready tables
4. Transformed data is available in the `dbt_transforms` schema

### Monitoring
- Check Airbyte sync status in the UI
- Monitor dbt runs via logs: `kubectl logs deployment/dbt-service -n airbyte`
- View transformation results in the database

## Troubleshooting

### Common Issues
1. **dbt connection errors**: Check database credentials and network connectivity
2. **Missing raw tables**: Ensure Airbyte syncs have completed successfully
3. **Permission errors**: Verify RBAC and service account permissions

### Useful Commands
```bash
# Check pod status
kubectl get pods -n airbyte

# View logs
kubectl logs deployment/dbt-service -n airbyte
kubectl logs deployment/airbyte-server -n airbyte

# Access database
kubectl exec -it deployment/airbyte-db-postgresql -n airbyte -- psql -U airbyte -d airbyte

# Port forward for local access
kubectl port-forward svc/airbyte-webapp-svc 8080:80 -n airbyte
```

## Cleanup
Run the teardown workflow to remove all resources:
```bash
# Via GitHub Actions
# Choose "teardown" action in the workflow

# Or manually
helm uninstall airbyte airbyte-db -n airbyte
kubectl delete namespace airbyte
gcloud container clusters delete $CLUSTER_NAME --region=$REGION
```

## Migration Notes

### Migrating from Old dbt Structure
If you have existing `dbt/` or `dbt-repo/` directories, use the cleanup script:
```bash
# Run the cleanup script to remove old directories
./cleanup-old-dbt.sh
```

The script will:
1. Create a backup of old directories
2. Remove the old `dbt/` and `dbt-repo/` directories
3. Keep the new consolidated structure in `dbt-config/`

### Key Changes in New Structure
- **Unified Configuration**: All dbt files now in `dbt-config/`
- **GitHub Actions Workflow**: New dedicated workflow at `.github/workflows/dbt-workflow.yml`
- **Improved Organization**: Clear separation between staging and mart models
- **Local Development**: New script `dbt-config/run-dbt-local.sh` for easier local testing