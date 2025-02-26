#!/bin/bash

# Disk usage threshold (in percentage)
THRESHOLD=80

# Get disk usage
DISK_USAGE=$(df -h)

# Show current disk space
echo "Current disk space:"
echo "$DISK_USAGE"

# Check if any filesystem exceeds the threshold
echo -e "\nChecking if any filesystem exceeds the $THRESHOLD% threshold..."

# Use awk to check for filesystems exceeding the threshold
ALERT_COUNT=$(df -h | awk '{if($5+0 > '$THRESHOLD') { print "Alert! Filesystem "$1" is at "$5" usage."; count++ }} END { if (count == 0) print "No filesystems exceed the threshold." }')

# Print the results
echo "$ALERT_COUNT"
