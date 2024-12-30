#!/bin/bash

echo "Replace base domain in the configuration files before proceeding."
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


cd setting-up-developer-hub-through-the-operator
sh cheat/run_all.sh
cd ..
cd github-integrations
sh cheat/run_all.sh