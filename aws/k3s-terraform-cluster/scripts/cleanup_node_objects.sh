#!/bin/bash

error_exit()
{
    echo "Error: $1"
    exit 1
}

threshold_time=$(date -d '30 minutes ago' -u +%Y-%m-%dT%H:%M:%SZ)
node_list=$(kubectl get nodes -o=json | jq -r '.items[] | select(.status.conditions[] | select(.type=="Ready" and .status!="True")) | .metadata.name + " " + .metadata.creationTimestamp')

if [ "$node_list" ]; then
    while IFS= read -r node_info; do
        node_name=$(echo "$node_info" | awk '{print $1}')
        creation_time=$(echo "$node_info" | awk '{print $2}')

        if [[ "$creation_time" < "$threshold_time" ]]; then
            echo "Deleting node $node_name..."
            kubectl delete node "$node_name" || error_exit "Failed to delete node $node_name, please check."
        else
            echo "Skipping node $node_name. Not eligible for deletion."
        fi
    done <<< "$node_list"
else
    echo "No nodes to cleanup, exiting."
fi