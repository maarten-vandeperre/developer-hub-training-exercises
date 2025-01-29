#!/bin/bash

# To run from a CI/CD pipeline:
# printf "\n" | sh cheat_script_run_all.sh

echo "Replace base domain in the .baseurl config file before proceeding."
echo "Replace namespace in the .namespace config file before proceeding."
echo "Press Enter to continue..."
read

# Check if the .baseurl file exists
if [[ ! -f .baseurl ]]; then
  echo "Error: .baseurl file not found in the current directory."
  exit 1
fi

# Read the base URL from the .baseurl file
BASE_URL=$(cat .baseurl)

if [[ -z "$BASE_URL" ]]; then
  echo "Error: .baseurl file is empty."
  exit 1
fi

echo "Base URL: $BASE_URL"

# Find and replace all occurrences of "rm1.0a51.p1.openshiftapps.com" in files (excluding .baseurl itself)
find . -type f -not -name ".baseurl" | while read -r file; do
  if grep -qE "cluster-.*\.opentlc\.com" "$file"; then
    echo "Updating file: $file"
    sed -i.bak "s/cluster-.*\.opentlc\.com/$BASE_URL/g" "$file"
    rm -f "$file.bak"
  fi

done

echo "Replacement of base URL completed."

# Read the namespace from the .namespace file
NAMESPACE=$(cat .namespace)

if [[ -z "$NAMESPACE" ]]; then
  echo "Error: .namespace file is empty."
  exit 1
fi

echo "Namespace: $NAMESPACE"

# Find and replace all occurrences of the default namespace in files (excluding .namespace itself)
find . -type f -not -name ".namespace" -not -name "run_all.sh" -not -name "cheat_script_run_all.sh" | while read -r file; do
  if grep -qE ": rh-ee-mvandepe-dev #project-namespace" "$file"; then
    echo "Updating file: $file"
    sed -i.bak "s/: rh-ee-mvandepe-dev #project-namespace/g" "$file"
    rm -f "$file.bak"
  fi

done

echo "Replacement of namespace completed."