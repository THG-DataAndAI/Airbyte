#!/bin/bash

# This script patches the Airbyte ConfigMap with resource limits after Helm deployment
# Add this to your GitHub workflow after the Helm deployment step

echo "Patching Airbyte ConfigMap with resource limits..."

# Create a ConfigMap patch
cat <<EOF > /tmp/configmap-patch.yaml
data:
  JOB_MAIN_CONTAINER_CPU_REQUEST: "500m"
  JOB_MAIN_CONTAINER_CPU_LIMIT: "2"
  JOB_MAIN_CONTAINER_MEMORY_REQUEST: "1Gi"
  JOB_MAIN_CONTAINER_MEMORY_LIMIT: "4Gi"
  SOURCE_CONTAINER_CPU_REQUEST: "500m"
  SOURCE_CONTAINER_CPU_LIMIT: "2"
  SOURCE_CONTAINER_MEMORY_REQUEST: "1Gi"
  SOURCE_CONTAINER_MEMORY_LIMIT: "4Gi"
  DESTINATION_CONTAINER_CPU_REQUEST: "500m"
  DESTINATION_CONTAINER_CPU_LIMIT: "2"
  DESTINATION_CONTAINER_MEMORY_REQUEST: "1Gi"
  DESTINATION_CONTAINER_MEMORY_LIMIT: "4Gi"
EOF

# Apply the patch
kubectl patch configmap airbyte-airbyte-env -n airbyte --patch-file /tmp/configmap-patch.yaml

if [ $? -eq 0 ]; then
    echo "✅ ConfigMap patched successfully!"
    
    # Restart workload-launcher to pick up new values
    echo "Restarting workload-launcher deployment..."
    kubectl rollout restart deployment airbyte-workload-launcher -n airbyte
    
    # Wait for rollout to complete
    kubectl rollout status deployment airbyte-workload-launcher -n airbyte --timeout=300s
    
    echo "✅ Deployment restarted successfully!"
    
    # Verify the values
    echo "Verifying ConfigMap values:"
    kubectl get configmap airbyte-airbyte-env -n airbyte -o yaml | grep -E "(JOB_MAIN|SOURCE|DESTINATION).*CONTAINER" | grep -v '""'
else
    echo "❌ Failed to patch ConfigMap"
    exit 1
fi

# Clean up
rm -f /tmp/configmap-patch.yaml