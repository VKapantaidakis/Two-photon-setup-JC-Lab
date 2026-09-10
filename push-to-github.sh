#!/bin/bash
# Push this repository to https://github.com/VKapantaidakis/Two-photon-setup-JC-Lab
#
# Run:   ./push-to-github.sh
#
# Git will ask for your GitHub username and password. For the password use a
# PERSONAL ACCESS TOKEN (github.com/settings/tokens -> Generate new token
# (classic) -> tick "repo"). GitHub no longer accepts account passwords.

set -e
REMOTE="https://github.com/VKapantaidakis/Two-photon-setup-JC-Lab.git"

git remote remove origin 2>/dev/null || true
git remote add origin "$REMOTE"
git branch -M main

echo ">> Pushing to $REMOTE"
git push -u origin main

echo
echo "Done: https://github.com/VKapantaidakis/Two-photon-setup-JC-Lab"
