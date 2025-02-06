#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

# Check if jq is installed (required for parsing JSON responses)
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required but not installed. Install it with 'brew install jq' on Mac."
  exit 1
fi

# Check if Ollama CLI is installed
if ! command -v ollama >/dev/null 2>&1; then
  echo "Error: Ollama CLI is required but not installed."
  exit 1
fi

generate_ai_commit_message() {
  local diff; diff=$(git diff --staged)
  
  if [ -z "$diff" ]; then
    echo "No changes detected."
    exit 1
  fi

  local prompt
  prompt="Generate a concise and informative commit message summarizing the following git diff, make sure NO other text but the commit message is present:\n\n${diff}"

  # Query the Ollama local model (llama3.2) with the prompt
  local commit_message
  commit_message=$(ollama run deepseek-r1:7b "$prompt")
  
  echo "DEBUG: Ollama response:" >&2
  echo "$commit_message" >&2

  # Remove everything between <think> and </think> using perl for multiline support
  commit_message=$(echo "$commit_message" | perl -0777 -pe 's/<think>.*?<\/think>//gs')


  # Fallback when the model returns nothing useful
  if [ -z "$commit_message" ] || [ "$commit_message" = "null" ]; then
    commit_message="Auto commit: $(date +'%Y-%m-%d %H:%M:%S')"
  fi

  echo "$commit_message"
}

# Loop through one level of directories in the current folder
for dir in */; do
  # Skip directories that don't contain a Git repository
  if [ ! -d "$dir/.git" ]; then
    continue
  fi

  echo "Processing repository in directory: $dir"
  cd "$dir"

  # Ensure we're in a Git repository with a current branch
  if ! current_branch=$(git branch --show-current 2>/dev/null) || [ -z "$current_branch" ]; then
    echo "Error: Not inside a Git repository or no current branch detected in $dir."
    cd ..
    continue
  fi

  # Add all changes to staging
  git add .

  # Check if there are changes staged for commit
  if git diff-index --quiet HEAD --; then
    echo "No changes to commit in $dir."
    cd ..
    continue
  fi

  # Generate AI commit message based on the diff of staged changes
  commit_message=$(generate_ai_commit_message 2>/dev/null)
  echo "Generated commit message: $commit_message"

  # Commit the changes with the AI generated message
  git commit -m "$commit_message"

  # Push the changes to the remote repository
  git push origin "$current_branch"

  # Return to the parent directory
  cd ..
done