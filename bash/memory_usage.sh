#!/bin/bash

# Define memory threshold in MB
THRESHOLD=1000

# Get memory available in MB
AVAILABLE=$(free -m | awk '/Mem/ {print $7}')

# Check if available memory is below threshold
if [ $AVAILABLE -lt $THRESHOLD ]; then
  echo "Low Memory Alert! Available memory: ${AVAILABLE}MB"
else
  echo "Memory is OK. Available memory: ${AVAILABLE}MB"
fi
