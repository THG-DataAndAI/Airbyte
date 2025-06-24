#!/bin/bash

# Deployment script for dbt in separate namespace

set -e

echo "========================================"
echo "Deploying dbt for Airbyte Transformations"
echo "========================================"

# Check prerequisites
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed"
    exit 1
fi

# Get Airbyte database password
echo "Please enter the Airbyte PostgreSQL password:"
echo "(This should match the AIRBYTE_DB_PASSWORD used in your Airbyte deployment)"
read -s DB_PASSWORD

if [ -z "$DB_PASSWORD" ]; then
    echo "Error: Password cannot be empty"
    exit 1
fi

# Create namespace
echo "Creating dbt namespace..."
kubectl apply -f k8s/namespace.yaml

# Create secret with the password
echo "Creating database secret..."
kubectl create secret generic dbt-postgres-secret \
    --namespace=dbt \
    --from-literal=password="$DB_PASSWORD" \
    --dry-run=client -o yaml | kubectl apply -f -

# Apply all other resources
echo "Deploying dbt resources..."
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/cronjob.yaml

# Wait for resources to be created
sleep 5

# Show deployment status
echo ""
echo "Deployment complete!"
echo "==================="
echo ""
echo "Resources created:"
kubectl get all -n dbt
echo ""
echo "CronJob schedule:"
kubectl get cronjob -n dbt
echo ""
echo "To run transformations manually:"
echo "  ./scripts/run_transformations.sh"
echo ""
echo "To check if dbt can connect to Airbyte's PostgreSQL:"
echo "  kubectl run -it --rm dbtest --image=postgres:13 --restart=Never -n dbt -- \\"
echo "    psql -h airbyte-db-postgresql.airbyte.svc.cluster.local -U airbyte -d airbyte -c 'SELECT 1;'"

# Make scripts executable
chmod +x scripts/run_transformations.sh

echo ""
echo "Setup complete! dbt will run automatically every 4 hours."
echo "You can also trigger manual runs using the script."