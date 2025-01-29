#!/bin/bash

# Developer Hub Training Exercise - Setting up Developer Hub Through the Operator

# Function to wait for specific condition
wait_for_pods_restart() {
  local delay=${1:-10} # Default delay is 10 seconds
  echo "Waiting for pods to be (re)started..."

  NAMESPACE="demo-project"
  COMMAND="oc get pods -n $NAMESPACE -o json | jq '.items[] | select(.metadata.ownerReferences[0].name | startswith(\"backstage-developer-hub-\")) | {POD: .metadata.name, DEPLOYMENT: .metadata.ownerReferences[0].name, Status: .status.phase, StartTime: .status.startTime }'"

  # Function to check if there is exactly one running pod
  check_single_pod_status() {
      RESULT=$(eval "$COMMAND")
      echo $RESULT
      POD_COUNT=$(echo "$RESULT" | jq -r "[. | select(.Status == \"Running\")] | length" ) || POD_COUNT=-1
      echo $POD_COUNT
      if [[ "$POD_COUNT" =~ ^[0-9]$ && "$POD_COUNT" -eq 1 ]]; then
          return 0 # Success: Exactly one running pod
      else
          return 1 # Failure: More or less than one running pod
      fi
  }

  # Wait for a pod with Status: "Running"
  echo "Waiting for a pod with {\"Status\": \"Running\"} in namespace $NAMESPACE..."
  sleep 5 # Wait for new pod to start
  echo "Waiting for exactly one pod with {\"Status\": \"Running\"} in namespace $NAMESPACE..."
  while true; do
      if check_single_pod_status; then
          echo "Exactly one pod with {\"Status\": \"Running\"} is found!"
          echo "Details:"
          echo "$RESULT" | jq '. | select(.Status == "Running")'
          break
      else
          echo "Condition not met yet. Retrying in $delay seconds..."
          sleep "$delay"
      fi
  done
}

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

echo "Replace base domain in the .baseurl config file before proceeding."
echo "Press Enter to continue..."
read


# Check if the .baseurl file exists
if [[ ! -f ../.baseurl ]]; then
  echo "Error: .baseurl file not found in the current parent directory."
  exit 1
fi

# Read the base URL from the .baseurl file
BASE_URL=$(cat ../.baseurl)
NAMESPACE=$(cat ../.namespace)

if [[ -z "$BASE_URL" ]]; then
  echo "Error: .baseurl file is empty."
  exit 1
fi

echo "Base URL: $BASE_URL"

# Find and replace all occurrences of "rm1.0a51.p1.openshiftapps.com" in files (excluding .baseurl itself)
find . -type f -not -name ".baseurl" -not -name "run_all" | while read -r file; do
  if grep -qE "cluster-.*\.opentlc\.com" "$file"; then
    echo "Updating file: $file"
    sed -i.bak "s/cluster-.*\.opentlc\.com/$BASE_URL/g" "$file"
    rm -f "$file.bak"
  fi

done

echo "Replacement of base URL completed."

if [[ -z "$NAMESPACE" ]]; then
  echo "Error: .namespace file is empty."
  exit 1
fi

echo "NAMESPACE: $NAMESPACE"

# Find and replace all occurrences of the default namespace in files (excluding .namespace itself)
find . -type f -not -name ".namespace" -not -name "run_all.sh" -not -name "cheat_script_run_all.sh" | while read -r file; do
  if grep -qE ":.* #project-namespace" "$file"; then
    echo "Updating file: $file"
    sed -i.bak "s/:.* #project-namespace/: $NAMESPACE #project-namespace/g" "$file"
    rm -f "$file.bak"
  fi

done

echo "Replacement of namespace completed."

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
echo "Wait for the Developer Hub operator to become healthy"
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
echo "Wait for the Developer Hub instance to become healthy"
wait_for_condition "oc get backstage -n $NAMESPACE -o json | jq -r '{ConditionType: .items[].status.conditions[].type, ConditionStatus: .items[].status.conditions[].status}'" "Deployed"

echo "Wait for pods to start"
wait_for_pods_restart
echo "Developer Hub setup completed successfully."