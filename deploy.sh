#!/bin/bash
# Blog Deploy Script - 自动构建并部署到 GitHub Pages
# Usage: ./deploy.sh [commit message]

set -e

BLOG_DIR="$HOME/blog"
DEPLOY_DIR="/tmp/blog-deploy"
COMMIT_MSG="${1:-deploy: $(date +%Y-%m-%d_%H:%M)}"

echo "🔨 Building site..."
cd "$BLOG_DIR"
hugo --minify

echo "📦 Preparing deploy..."
rm -rf "$DEPLOY_DIR"
cp -r public "$DEPLOY_DIR"
cd "$DEPLOY_DIR"
git init
git checkout -B gh-pages
git add -A
git commit -m "$COMMIT_MSG"

echo "🚀 Deploying to GitHub Pages..."
git push --force https://github.com/rsliyu/rsliyu.github.io.git gh-pages

echo "📤 Pushing source..."
cd "$BLOG_DIR"
git add -A
git diff --cached --quiet || git commit -m "$COMMIT_MSG"
git push origin main

echo "✅ Done! Site live at https://rsliyu.github.io/"
