#!/bin/bash

# Prompt for GitHub repository
read -p "Enter GitHub repository (OWNER/REPO): " REPO

# Prompt for the file containing secrets
read -p "Enter the path to the secrets file: " FILE_PATH

# Check if the file exists
if [[ ! -f "$FILE_PATH" ]]; then
    echo "❌ File not found: $FILE_PATH"
    exit 1
fi

# Read the file line by line
while IFS='=' read -r SECRET_NAME SECRET_VALUE; do
    # Skip empty lines and comments
    [[ -z "$SECRET_NAME" || "$SECRET_NAME" == \#* ]] && continue

    # Trim spaces
    SECRET_NAME=$(echo "$SECRET_NAME" | xargs)
    SECRET_VALUE=$(echo "$SECRET_VALUE" | xargs)

    # Validate SECRET_NAME
    if [[ ! "$SECRET_NAME" =~ ^[A-Za-z0-9_]+$ ]]; then
        echo "⚠️ Skipping invalid secret name: $SECRET_NAME"
        continue
    fi

    # Set the secret using GitHub CLI
    gh secret set "$SECRET_NAME" --body "$SECRET_VALUE" -R "$REPO"

    # Confirmation
    if [[ $? -eq 0 ]]; then
        echo "✅ Secret '$SECRET_NAME' set successfully!"
    else
        echo "❌ Failed to set secret '$SECRET_NAME'"
    fi
done < "$FILE_PATH"

echo "✅ All secrets from $FILE_PATH have been processed!"
