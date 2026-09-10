#!/bin/bash
# Push this repository to a NEW, EMPTY GitHub repository.
#
# 1. Create an empty repo on GitHub first (no README, no .gitignore, no licence):
#       https://github.com/new
#    Suggested name: two-photon-setup-JC-Lab
#
# 2. Run:
#       ./push-to-github.sh <github-username> [repo-name]

set -e
USER="${1:?Usage: ./push-to-github.sh <github-username> [repo-name]}"
REPO="${2:-two-photon-setup-JC-Lab}"

git remote remove origin 2>/dev/null || true
git remote add origin "https://github.com/${USER}/${REPO}.git"
git branch -M main

echo ">> Pushing to https://github.com/${USER}/${REPO}"
git push -u origin main

echo
echo "Done: https://github.com/${USER}/${REPO}"
