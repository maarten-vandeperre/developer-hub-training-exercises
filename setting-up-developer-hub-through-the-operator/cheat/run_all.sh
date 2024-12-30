#!/bin/bash

# Developer Hub Training Exercise - Setting up Developer Hub Through the Operator

# Function to wait for a specific condition
wait_for_condition() {
  local command="$1"
  local expected_output="$2"
  local delay=${3:-10} # Default delay is 10 seconds
  echo "Waiting for condition: $expected_output"

  while true; do
    output=$(eval "$command")
    echo "Current status: $output"

    if [[ "$output" == *"$expected_output"* ]]; then
      echo "Condition met: $expected_output"
      break
    fi

    echo "Retrying in $delay seconds..."
    sleep $delay
  done
}

# Check if the .baseurl file exists
if [[ ! -f .baseurl ]]; then
  echo "Error: .baseurl file not found in the current directory."
  exit 1
fi

# Read the base URL from the .baseurl file
BASE_URL=$(cat ../.baseurl)

if [[ -z "$BASE_URL" ]]; then
  echo "Error: .baseurl file is empty."
  exit 1
fi

echo "Base URL: $BASE_URL"

# Find and replace all occurrences of "cluster-<...>.opentlc.com" in files (excluding .baseurl itself)
find . -type f -not -name ".baseurl" | while read -r file; do
  if grep -qE "cluster-.*\.opentlc\.com" "$file"; then
    echo "Updating file: $file"
    sed -i.bak "s/cluster-.*\.opentlc\.com/$BASE_URL/g" "$file"
    rm -f "$file.bak"
  fi

done

echo "Replacement completed."

# Step 1: Create namespaces
echo "Applying namespaces manifest..."
oc apply -f manifests/namespaces.yaml

# Step 2: Create operator groups
echo "Applying operator groups manifest..."
oc apply -f manifests/operator-groups.yaml

# Step 3: Install operator
echo "Applying operator manifest..."
oc apply -f manifests/operator.yaml

# Step 4: Wait for the Developer Hub operator to become healthy
wait_for_condition "oc get clusterserviceversion -n openshift-operators -o json | jq -r '{Status: .items[].status.phase}'" "Succeeded"

# Step 5: Create secret with base information
echo "Applying secrets manifest..."
oc apply -f manifests/secrets_rdhd-secret.yaml

# Step 6: Create dynamic plugin root persistent volume
echo "Applying PVC manifest..."
oc apply -f manifests/pvc_dynamic-plugin-root.yaml

# Step 7: Install Developer Hub instance
echo "Applying Developer Hub instance manifest..."
oc apply -f manifests/developer-hub-instance.yaml

# Step 8: Wait for the Developer Hub instance to become healthy
wait_for_condition "oc get backstage -n demo-project -o json | jq -r '{ConditionType: .items[].status.conditions[].type, ConditionStatus: .items[].status.conditions[].status}'" "Deployed"

echo "Developer Hub setup completed successfully."