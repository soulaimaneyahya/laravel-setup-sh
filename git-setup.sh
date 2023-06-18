#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Please provide a project name."
    exit 1
fi

cd $1
git init
git add .
git commit -m "Initial commit"
git branch -M main
echo "Enter your GitHub repository URL (e.g., https://github.com/username/repo):"
read repo_url
git remote add origin $repo_url
git push -u origin main

if [ $? -eq 0 ]; then
    echo "== Successfully pushed to GitHub =="
else
    echo "== Failed to push to GitHub =="
fi
