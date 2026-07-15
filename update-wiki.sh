#!/bin/bash

echo "📂 Copying wiki files..."
cp -r "/Users/christelle.nollet/Documents/Obsidian Vault/wiki/." ~/robotics-wiki-v2/content/

echo "📝 Committing changes..."
cd ~/robotics-wiki-v2
git add .
git commit -m "Update wiki $(date '+%Y-%m-%d')"

echo "🚀 Pushing to GitHub..."
git push origin main

echo "✅ Done — site will rebuild in ~2 minutes"
echo "🔗 https://christelle1208.github.io/robotics-wiki-v2/"
