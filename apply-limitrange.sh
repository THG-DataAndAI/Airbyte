#!/bin/bash

echo "Applying LimitRange to enforce container resource limits in Airbyte namespace..."

# Apply the LimitRange
kubectl apply -f airbyte-limitrange.yaml

if [ $? -eq 0 ]; then
    echo "✅ LimitRange applied successfully!"
    
    # Show the current LimitRange
    echo ""
    echo "Current LimitRange configuration:"
    kubectl describe limitrange airbyte-container-limits -n airbyte
    
    echo ""
    echo "⚠️  Note: This LimitRange will apply to NEW pods created after this point."
    echo "Existing pods will keep their current resource limits."
    echo ""
    echo "To apply to existing workloads, you need to restart them:"
    echo "kubectl rollout restart deployment --all -n airbyte"
else
    echo "❌ Failed to apply LimitRange"
    exit 1
fi