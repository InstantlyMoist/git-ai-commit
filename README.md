# git-ai-commit

Updates all your repositories, and writes AI commit messages for them.

This script loops through every child directory, looks at the `git diff` and creates a commit message out of it. It will then automatically commit and push it to the latest branch.

# Prerequisites

- jq
- Ollama (https://ollama.com/)

# How to run
```bash
$ git clone https://github.com/InstantlyMoist/git-ai-commit
$ mv ./git-ai-commit/autocommit.sh ~/your-desired-directory
$ chmod +x ~/your-desired-directory/autocommit.sh
$ ~/your-desired-directory/autocommit.sh
```

# Tested with model
- deepseek-r1:7b
