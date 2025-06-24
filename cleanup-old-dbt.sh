#!/bin/bash

# Script to clean up old dbt directories after migration to new structure

echo "======================================"
echo "dbt Directory Cleanup Script"
echo "======================================"
echo ""
echo "This script will help you clean up the old dbt directories"
echo "after migrating to the new consolidated structure."
echo ""
echo "Current dbt structure:"
echo "- Old directories: dbt/ and dbt-repo/"
echo "- New directory: dbt-config/"
echo ""

# Check if new structure exists
if [ ! -d "dbt-config" ]; then
    echo "Error: New dbt-config directory not found!"
    echo "Please ensure the migration is complete before running this script."
    exit 1
fi

# Show what will be removed
echo "The following directories will be removed:"
echo ""
if [ -d "dbt" ]; then
    echo "  - dbt/"
    du -sh dbt/ 2>/dev/null || echo "    (size calculation failed)"
fi
if [ -d "dbt-repo" ]; then
    echo "  - dbt-repo/"
    du -sh dbt-repo/ 2>/dev/null || echo "    (size calculation failed)"
fi

echo ""
echo "The new consolidated structure is in: dbt-config/"
echo ""

# Confirm with user
read -p "Are you sure you want to remove the old dbt directories? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

# Create backup first
echo ""
echo "Creating backup of old directories..."
backup_dir="dbt-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup_dir"

if [ -d "dbt" ]; then
    echo "Backing up dbt/ to $backup_dir/dbt/"
    cp -r dbt "$backup_dir/"
fi

if [ -d "dbt-repo" ]; then
    echo "Backing up dbt-repo/ to $backup_dir/dbt-repo/"
    cp -r dbt-repo "$backup_dir/"
fi

echo "Backup created in: $backup_dir"

# Remove old directories
echo ""
echo "Removing old directories..."

if [ -d "dbt" ]; then
    echo "Removing dbt/"
    rm -rf dbt/
fi

if [ -d "dbt-repo" ]; then
    echo "Removing dbt-repo/"
    rm -rf dbt-repo/
fi

echo ""
echo "Cleanup completed!"
echo ""
echo "Summary:"
echo "- Old directories have been removed"
echo "- Backup saved in: $backup_dir"
echo "- New dbt configuration is in: dbt-config/"
echo ""
echo "Next steps:"
echo "1. Update any scripts or documentation that reference the old paths"
echo "2. Test the new dbt workflow: .github/workflows/dbt-workflow.yml"
echo "3. Remove the backup directory once you're confident: rm -rf $backup_dir"