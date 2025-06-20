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

# Build and deploy dbt
cd dbt
docker build -t gcr.io/$PROJECT_ID/dbt-airbyte:latest .
docker push gcr.io/$PROJECT_ID/dbt-airbyte:latest
kubectl apply -f k8s/dbt-deployment.yaml

# Deploy Airbyte
helm repo add airbyte https://airbytehq.github.io/helm-charts
helm install airbyte airbyte/airbyte --namespace=airbyte --values values.yaml
```

## dbt Configuration

### Models Structure
```
dbt/models/
├── staging/
│   ├── _sources.yml          # Source definitions
│   └── stg_raw_data.sql      # Staging models
└── marts/
    ├── schema.yml            # Model documentation and tests
    ├── dim_users.sql         # Dimension tables
    └── fact_sync_metrics.sql # Fact tables
```

### Running dbt Transformations
```bash
# Make script executable
chmod +x dbt/scripts/run_dbt.sh

# Run transformations
./dbt/scripts/run_dbt.sh
```

### Manual dbt Commands
```bash
# Connect to dbt pod
kubectl exec -it deployment/dbt-service -n airbyte -- /bin/bash

# Inside the pod
dbt run --profiles-dir /dbt/profiles
dbt test --profiles-dir /dbt/profiles
dbt docs generate --profiles-dir /dbt/profiles
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