#!/bin/bash

# Script to run dbt transformations locally
# This script helps developers test dbt models before deploying to Kubernetes

set -e

echo "======================================"
echo "dbt Local Runner for Airbyte"
echo "======================================"

# Check if dbt is installed
if ! command -v dbt &> /dev/null; then
    echo "Error: dbt is not installed"
    echo "Please install dbt-postgres: pip install dbt-postgres"
    exit 1
fi

# Set default values
DBT_PROJECT_DIR="${DBT_PROJECT_DIR:-$(dirname "$0")}"
DBT_PROFILES_DIR="${DBT_PROFILES_DIR:-$DBT_PROJECT_DIR/profiles}"
DBT_TARGET="${DBT_TARGET:-dev}"

# Check required environment variables
if [ -z "$DBT_DATABASE_PASSWORD" ]; then
    echo "Error: DBT_DATABASE_PASSWORD environment variable is not set"
    echo "Please set it with: export DBT_DATABASE_PASSWORD=your-password"
    exit 1
fi

# Function to run dbt commands
run_dbt_command() {
    local command=$1
    local args=$2
    echo "Running: dbt $command $args"
    dbt $command --profiles-dir="$DBT_PROFILES_DIR" --project-dir="$DBT_PROJECT_DIR" --target="$DBT_TARGET" $args
}

# Main menu
echo ""
echo "What would you like to do?"
echo "1) Run all models"
echo "2) Run specific models"
echo "3) Test all models"
echo "4) Run and test"
echo "5) Generate documentation"
echo "6) Serve documentation"
echo "7) List all models"
echo "8) Clean project"
echo "9) Exit"
echo ""
read -p "Select option (1-9): " choice

case $choice in
    1)
        echo "Running all dbt models..."
        run_dbt_command "run" ""
        ;;
    2)
        echo "Available models:"
        run_dbt_command "list" "--resource-type model"
        echo ""
        read -p "Enter model name or tag to run: " model
        run_dbt_command "run" "--models $model"
        ;;
    3)
        echo "Testing all models..."
        run_dbt_command "test" ""
        ;;
    4)
        echo "Running models and tests..."
        run_dbt_command "run" ""
        echo ""
        run_dbt_command "test" ""
        ;;
    5)
        echo "Generating documentation..."
        run_dbt_command "docs" "generate"
        echo "Documentation generated in target/ directory"
        ;;
    6)
        echo "Serving documentation..."
        echo "Documentation will be available at http://localhost:8080"
        run_dbt_command "docs" "serve"
        ;;
    7)
        echo "Listing all models..."
        run_dbt_command "list" "--resource-type model"
        ;;
    8)
        echo "Cleaning dbt project..."
        run_dbt_command "clean" ""
        ;;
    9)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac

echo ""
echo "Operation completed!"
echo ""
echo "To view results in PostgreSQL:"
echo "psql -h \$DBT_DATABASE_HOST -U \$DBT_DATABASE_USER -d \$DBT_DATABASE_NAME -c 'SELECT * FROM dbt_transforms.dim_customers LIMIT 10;'"