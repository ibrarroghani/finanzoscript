#!/bin/bash

# Function to prompt for input until a valid value is entered
prompt_for_input() {
    local prompt_message="$1"
    local input_variable
    while true; do
        read -p "$prompt_message" input_variable
        if [[ -n "$input_variable" ]]; then
            echo "$input_variable"
            return
        else
            echo "❌ You didn't enter a value. Please try again."
        fi
    done
}

# Function to securely prompt for GitHub token
prompt_for_token() {
    while true; do
        read -s -p "🔑 Enter your GitHub token: " GITHUB_TOKEN
        echo ""  # Move to a new line after input
        if [[ -n "$GITHUB_TOKEN" ]]; then
            return
        else
            echo "❌ You didn't enter a token. Please try again."
        fi
    done
}

# Function to validate visibility input
prompt_for_visibility() {
    while true; do
        read -p "🌍 Visibility (public/private): " VISIBILITY
        if [[ "$VISIBILITY" == "public" || "$VISIBILITY" == "private" ]]; then
            echo "$VISIBILITY"
            return
        else
            echo "❌ Invalid visibility. Please enter 'public' or 'private'."
        fi
    done
}

# Prompt for user input
prompt_for_token
GITHUB_USER=$(prompt_for_input "👤 GitHub username: ")
REPO_NAME=$(prompt_for_input "📂 Repository name: ")
DESCRIPTION=$(prompt_for_input "📝 Repository description: ")
VISIBILITY=$(prompt_for_visibility)
LOCAL_CLONE_PATH=$(prompt_for_input "📍 Local repo path: ")

# Display summary
echo -e "\n🔍 **Repository Details:**"
echo "------------------------------------"
echo "👤 GitHub Username      : $GITHUB_USER"
echo "📂 Repository Name      : $REPO_NAME"
echo "📝 Description          : $DESCRIPTION"
echo "🌍 Visibility           : $VISIBILITY"
echo "📍 Local Repo Path      : $LOCAL_CLONE_PATH"
echo "------------------------------------"

# Confirm before proceeding
while true; do
    read -p "⚠️ Do you want to proceed? (y/n): " CONFIRMATION
    case "$CONFIRMATION" in
        y|Y ) break ;;   # Proceed with script
        n|N ) echo "🚫 Operation cancelled."; exit 0 ;;
        * ) echo "❌ Invalid input. Please enter 'y' or 'n'." ;;
    esac
done

# Authenticate GitHub
echo "🔄 Logging into GitHub..."
echo "$GITHUB_TOKEN" | gh auth login --with-token
if [[ $? -ne 0 ]]; then
    echo "❌ GitHub authentication failed! Exiting..."
    exit 1
fi

# Create GitHub repository
echo "📦 Creating GitHub repository..."
GH_TOKEN="$GITHUB_TOKEN" gh repo create "$REPO_NAME" --$VISIBILITY --description "$DESCRIPTION" --confirm
if [[ $? -ne 0 ]]; then
    echo "❌ Failed to create repository! Exiting..."
    exit 1
fi

# Verify local repo path
if [[ ! -d "$LOCAL_CLONE_PATH" ]]; then
    echo "❌ Local repository not found at $LOCAL_CLONE_PATH. Exiting..."
    exit 1
fi

# Move to local repository
cd "$LOCAL_CLONE_PATH" || exit

# Initialize Git if not already initialized
if [[ ! -d ".git" ]]; then
    echo "🔧 the repo path is incorect plz provide the correct path "
    exit 1
fi

# Set remote origin
echo "🔗 Setting remote origin..."
git remote remove origin 2>/dev/null
git remote add origin "https://github.com/$GITHUB_USER/$REPO_NAME.git"

# Push code
echo "🚀 Pushing code to GitHub..."
git add .
#git commit -m "push to $REPO_NAME" || echo "⚠️ No new changes to commit."
git branch -M main
git push -u origin main

echo "✅ Repository created and code pushed successfully!"
