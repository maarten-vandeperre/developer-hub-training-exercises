#!/bin/bash

# To run from a CI/CD pipeline:
# printf "\n" | sh cheat_script_run_all.sh

echo "Replace base domain in the .baseurl config file before proceeding."
echo "Replace namespace in the .namespace config file before proceeding."
echo "Press Enter to continue..."
read

FILE_SECRETS_GITHUB_CREDENTIALS="github-integrations/.confidential/secrets_github-credentials.yaml"
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
find . -type f -not -name ".namespace" -not -name "run_all.sh" -not -name "cheat_script_run_all.sh" -not -name "replace_base_url.sh" | while read -r file; do
  if grep -qE ":.* #project-namespace" "$file"; then
    echo "Updating file: $file"
    sed -i.bak "s/:.* #project-namespace/: $NAMESPACE #project-namespace/g" "$file"
    rm -f "$file.bak"
  fi

done

echo "Replacement of namespace completed."


cd setting-up-developer-hub-through-the-operator
sh cheat/run_all.sh
cd ..
cd github-integrations
sh cheat/run_all.sh
