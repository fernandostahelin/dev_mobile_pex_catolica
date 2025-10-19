#!/bin/bash

# Flutter PEX CI Script
# Simple script to run the local CI process

set -e  # Exit on any error

echo "🚀 Starting Flutter PEX CI Process..."

# Check if Make is available
if ! command -v make &> /dev/null; then
    echo "❌ Error: Make is not installed. Please install make to use this script."
    exit 1
fi

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Error: Flutter is not installed or not in PATH."
    exit 1
fi

# Run the CI pipeline
echo "📋 Running CI pipeline..."
make ci

echo "✅ CI Process completed successfully!"
echo ""
echo "🎉 Your code is ready to push to GitHub!"
echo ""
echo "💡 Tip: Run 'make help' to see all available commands"
