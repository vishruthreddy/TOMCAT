#!/bin/bash
# Script to push TOMCAT repository to GitHub
# Run this after creating the repository on GitHub

echo "Setting up remote repository..."
git remote add origin https://github.com/vishruthreddy/TOMCAT.git

echo "Pushing to GitHub..."
git branch -M main
git push -u origin main

echo "Done! Your repository is now on GitHub."
echo "Visit: https://github.com/vishruthreddy/TOMCAT"

