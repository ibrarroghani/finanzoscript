#!/bin/bash
# this script will set all varibale for github action
# Prompt for GitHub repository
read -p "Enter GitHub repository (OWNER/REPO): " REPO

# Prompt for the file containing variables
read -p "Enter the path to the variables file: " FILE_PATH

# Check if the file exists
if [[ ! -f "$FILE_PATH" ]]; then
    echo "❌ File not found: $FILE_PATH"
    exit 1
fi

# Read the file line by line
while IFS='=' read -r VAR_NAME VAR_VALUE; do
    # Skip empty lines and comments
    [[ -z "$VAR_NAME" || "$VAR_NAME" == \#* ]] && continue

    # Trim spaces
    VAR_NAME=$(echo "$VAR_NAME" | xargs)
    VAR_VALUE=$(echo "$VAR_VALUE" | xargs)

    # Validate VAR_NAME
    if [[ ! "$VAR_NAME" =~ ^[A-Za-z0-9_]+$ ]]; then
        echo "⚠️ Skipping invalid variable name: $VAR_NAME"
        continue
    fi

    # Set the variable using GitHub CLI
    gh variable set "$VAR_NAME" --body "$VAR_VALUE" -R "$REPO"

    # Confirmation
    if [[ $? -eq 0 ]]; then
        echo "✅ Variable '$VAR_NAME' set successfully!"
    else
        echo "❌ Failed to set variable '$VAR_NAME'"
    fi
done < "$FILE_PATH"

echo "✅ All variables from $FILE_PATH have been processed!"
