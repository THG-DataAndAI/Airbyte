#!/bin/bash

# Script to run dbt transformations in Kubernetes

set -e

echo "======================================"
echo "dbt Transformation Runner for Airbyte"
echo "======================================"

# Set namespace
NAMESPACE=${NAMESPACE:-airbyte}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed or not in PATH"
    exit 1
fi

# Check if we can connect to the cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Cannot connect to Kubernetes cluster"
    exit 1
fi

# Check if dbt service exists
if ! kubectl get deployment dbt-service -n $NAMESPACE &> /dev/null; then
    echo "Error: dbt-service deployment not found in namespace $NAMESPACE"
    echo "Please ensure the dbt service is deployed first"
    exit 1
fi

# Function to run dbt using a Job
run_dbt_job() {
    echo "Creating dbt transformation job..."
    
    # Delete any existing manual run job
    kubectl delete job dbt-manual-run -n $NAMESPACE 2>/dev/null || true
    
    # Apply the manual job
    kubectl apply -f dbt/k8s/dbt-cronjob.yaml -n $NAMESPACE
    
    # Wait for job to complete
    echo "Waiting for dbt job to complete..."
    kubectl wait --for=condition=complete job/dbt-manual-run -n $NAMESPACE --timeout=600s
    
    # Show logs
    echo ""
    echo "dbt transformation logs:"
    echo "========================"
    kubectl logs job/dbt-manual-run -n $NAMESPACE
    
    # Cleanup
    kubectl delete job dbt-manual-run -n $NAMESPACE
}

# Function to run dbt directly in the service pod
run_dbt_direct() {
    echo "Running dbt transformations directly in service pod..."
    
    # Get the pod name
    POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=dbt-service -o jsonpath='{.items[0].metadata.name}')
    
    if [ -z "$POD_NAME" ]; then
        echo "Error: No dbt-service pod found"
        exit 1
    fi
    
    echo "Using pod: $POD_NAME"
    echo ""
    
    # Run dbt commands
    echo "Running dbt run..."
    kubectl exec -n $NAMESPACE $POD_NAME -- dbt run --profiles-dir /dbt/profiles --project-dir /dbt
    
    echo ""
    echo "Running dbt test..."
    kubectl exec -n $NAMESPACE $POD_NAME -- dbt test --profiles-dir /dbt/profiles --project-dir /dbt
}

# Main menu
echo ""
echo "How would you like to run dbt transformations?"
echo "1) Run as a Kubernetes Job (recommended)"
echo "2) Run directly in dbt service pod"
echo "3) Schedule automatic runs (deploy CronJob)"
echo "4) View dbt service logs"
echo "5) Exit"
echo ""
read -p "Select option (1-5): " choice

case $choice in
    1)
        run_dbt_job
        ;;
    2)
        run_dbt_direct
        ;;
    3)
        echo "Deploying dbt CronJob for automatic runs..."
        kubectl apply -f dbt/k8s/dbt-cronjob.yaml
        echo "CronJob deployed! dbt will run automatically every 4 hours."
        echo "To check CronJob status: kubectl get cronjobs -n $NAMESPACE"
        ;;
    4)
        echo "Showing dbt service logs..."
        kubectl logs deployment/dbt-service -n $NAMESPACE --tail=100
        ;;
    5)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac

echo ""
echo "dbt operation completed!"
echo ""
echo "To view transformed data:"
echo "kubectl exec -it deployment/airbyte-db-postgresql -n $NAMESPACE -- psql -U airbyte -d airbyte -c '\dt dbt_transforms.*'"