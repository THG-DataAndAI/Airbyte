#!/bin/bash

# Script to run dbt transformations in the separate dbt namespace

set -e

echo "======================================"
echo "dbt Transformation Runner"
echo "======================================"

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

# Function to create a one-time job from the CronJob
run_dbt_job() {
    echo "Creating one-time dbt transformation job..."
    
    # Generate unique job name
    JOB_NAME="dbt-manual-$(date +%s)"
    
    # Create job from cronjob
    kubectl create job --from=cronjob/dbt-transformations $JOB_NAME -n dbt
    
    echo "Job $JOB_NAME created. Waiting for completion..."
    
    # Wait for job to complete
    kubectl wait --for=condition=complete job/$JOB_NAME -n dbt --timeout=600s || {
        echo "Job did not complete within timeout. Checking status..."
        kubectl describe job/$JOB_NAME -n dbt
    }
    
    # Show logs
    echo ""
    echo "Job logs:"
    echo "========="
    kubectl logs job/$JOB_NAME -n dbt
    
    # Show job status
    echo ""
    echo "Job status:"
    kubectl get job/$JOB_NAME -n dbt
}

# Function to view recent job history
view_job_history() {
    echo "Recent dbt transformation jobs:"
    echo "=============================="
    kubectl get jobs -n dbt --sort-by=.metadata.creationTimestamp | tail -10
}

# Function to view CronJob status
view_cronjob_status() {
    echo "CronJob status:"
    echo "==============="
    kubectl get cronjob dbt-transformations -n dbt
    echo ""
    echo "Next scheduled run:"
    kubectl get cronjob dbt-transformations -n dbt -o jsonpath='{.status.lastScheduleTime}{"\n"}'
}

# Function to test database connection
test_connection() {
    echo "Testing database connection from dbt namespace..."
    
    # Get the password from secret
    DB_PASSWORD=$(kubectl get secret dbt-postgres-secret -n dbt -o jsonpath='{.data.password}' | base64 -d)
    
    # Run a test pod
    kubectl run -it --rm dbtest --image=postgres:13 --restart=Never -n dbt -- \
        psql -h airbyte-db-postgresql.airbyte.svc.cluster.local -U airbyte -d airbyte -c "SELECT 1;"
}

# Main menu
echo ""
echo "What would you like to do?"
echo "1) Run dbt transformations now"
echo "2) View job history"
echo "3) View CronJob status"
echo "4) Test database connection"
echo "5) View transformed data"
echo "6) Exit"
echo ""
read -p "Select option (1-6): " choice

case $choice in
    1)
        run_dbt_job
        ;;
    2)
        view_job_history
        ;;
    3)
        view_cronjob_status
        ;;
    4)
        test_connection
        ;;
    5)
        echo "Connecting to PostgreSQL to view transformed data..."
        kubectl exec -it deployment/airbyte-db-postgresql -n airbyte -- \
            psql -U airbyte -d airbyte -c "SELECT * FROM dbt_transforms.dim_customers LIMIT 10;"
        ;;
    6)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac