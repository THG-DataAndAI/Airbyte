#!/bin/bash

# Script to run dbt transformations in Kubernetes

set -e

echo "Starting dbt transformations..."

# Set namespace
NAMESPACE=${NAMESPACE:-airbyte}

# Function to run dbt commands
run_dbt_command() {
    local command=$1
    echo "Running: dbt $command"
    
    kubectl exec -n $NAMESPACE deployment/dbt-service -- \
        dbt $command --profiles-dir /dbt/profiles --project-dir /dbt
}

# Install dbt dependencies (if any)
echo "Installing dbt dependencies..."
run_dbt_command "deps"

# Run dbt debug to check connections
echo "Checking dbt connections..."
run_dbt_command "debug"

# Run dbt models
echo "Running dbt models..."
run_dbt_command "run"

# Run dbt tests
echo "Running dbt tests..."
run_dbt_command "test"

# Generate documentation
echo "Generating dbt documentation..."
run_dbt_command "docs generate"

echo "dbt transformations completed successfully!"

# Optional: Start docs server (uncomment if needed)
# echo "Starting dbt docs server..."
# kubectl exec -n $NAMESPACE deployment/dbt-service -- \
#     dbt docs serve --profiles-dir /dbt/profiles --project-dir /dbt --host 0.0.0.0 --port 8080 &