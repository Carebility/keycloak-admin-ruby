#!/bin/bash

# Create the carebility network if it doesn't exist
echo "Checking Docker network configuration..."

if ! docker network ls | grep -q "carebility"; then
  echo "Creating 'carebility' Docker network..."
  docker network create carebility
  echo "✅ Network 'carebility' created successfully"
else
  echo "✅ Network 'carebility' already exists"
fi
