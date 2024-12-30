#!/bin/bash

# Developer Hub Training Exercise - Adding GitHub Integration

# Function to wait for specific condition
wait_for_pods_restart() {
  local delay=${1:-10} # Default delay is 10 seconds
  echo "Waiting for pods to be restarted..."

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

FILE_SECRETS_GITHUB_CREDENTIALS=".confidential/secrets_github-credentials.yaml"

# Check if the file exists
if [ ! -f "$FILE_SECRETS_GITHUB_CREDENTIALS" ]; then
  echo "The file '$FILE_SECRETS_GITHUB_CREDENTIALS' does not exist."
  echo "Please create the file and press Enter to continue."
  # Wait for the user to press Enter
  read -p ""
  # Recheck if the file exists after the user has pressed Enter
  if [ ! -f "$FILE_SECRETS_GITHUB_CREDENTIALS" ]; then
    echo "The file '$FILE_SECRETS_GITHUB_CREDENTIALS' is still missing. Exiting."
    exit 1
  else
    echo "File '$FILE_SECRETS_GITHUB_CREDENTIALS' found. Proceeding."
  fi
else
  echo "File '$FILE_SECRETS_GITHUB_CREDENTIALS' already exists. Proceeding."
fi

# Step 1: Apply GitHub credentials secret
# Ensure you have updated the YAML file with your GitHub app credentials before applying.
echo "Applying GitHub credentials secret manifest..."
oc apply -f $FILE_SECRETS_GITHUB_CREDENTIALS

# Step 2: Create dynamic plugins configuration
echo "Applying dynamic plugins configuration manifest..."
oc apply -f manifests/dynamic-plugins-v5.yaml

# Step 3: Create app config configuration
echo "Applying app config configuration manifest..."
oc apply -f manifests/app-config-v5.yaml

# Step 4: Apply the updated instance config
echo "Applying updated instance configuration manifest..."
oc apply -f manifests/instance-config-v1.yaml

# Step 5: Wait for pods to restart to avoid unexpected behavior
wait_for_pods_restart

echo "GitHub integration setup completed successfully."
