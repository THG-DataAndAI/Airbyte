#!/bin/bash

# Setup script for dbt integration with Airbyte

set -e

echo "Setting up dbt integration for Airbyte..."

# Set namespace
NAMESPACE=${NAMESPACE:-airbyte}

# Function to check if kubectl is available and configured
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        echo "kubectl is not configured or cluster is not accessible"
        exit 1
    fi
}

# Function to wait for deployment to be ready
wait_for_deployment() {
    local deployment=$1
    echo "Waiting for $deployment to be ready..."
    kubectl wait --for=condition=available deployment/$deployment \
        -n $NAMESPACE --timeout=300s
}

# Function to create database schema
setup_database_schema() {
    echo "Setting up dbt_transforms schema..."
    
    # Wait for PostgreSQL to be ready
    wait_for_deployment "airbyte-db-postgresql"
    
    # Create schema if it doesn't exist
    kubectl exec -n $NAMESPACE deployment/airbyte-db-postgresql -- \
        psql -U airbyte -d airbyte -c "CREATE SCHEMA IF NOT EXISTS dbt_transforms;" || \
        echo "Schema might already exist or connection failed"
}

# Main setup function
main() {
    echo "Starting dbt setup process..."
    
    # Check prerequisites
    check_kubectl
    
    # Ensure namespace exists
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    # Setup database schema
    setup_database_schema
    
    # Apply dbt Kubernetes resources
    echo "Applying dbt Kubernetes resources..."
    kubectl apply -f dbt/k8s/dbt-deployment.yaml
    
    # Wait for dbt service to be ready
    wait_for_deployment "dbt-service"
    
    echo "dbt setup completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Set up your Airbyte connections to extract data"
    echo "2. Run dbt transformations using: ./dbt/scripts/run_dbt.sh"
    echo "3. Monitor dbt service: kubectl logs deployment/dbt-service -n $NAMESPACE"
    echo ""
    echo "dbt service is now running and ready to process your data!"
}

# Run main function
main