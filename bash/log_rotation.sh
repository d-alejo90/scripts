#!/bin/bash

# Default values for log directory and script log file
DEFAULT_LOG_DIR="/var/log/app/"
DEFAULT_LOG_FILE="/var/log/app/script.log"

# Check if log directory and script log file are provided as arguments
if [ $# -ge 1 ]; then
  LOG_DIR=$1
  if [ $# -ge 2 ]; then
    LOG_FILE=$2
  else
    LOG_FILE="$LOG_DIR/script.log"
  fi
else
  LOG_DIR=$DEFAULT_LOG_DIR
  LOG_FILE=$DEFAULT_LOG_FILE
fi

# Log script start
echo "[$(date +%F_%T)] Starting script." >>$LOG_FILE

# Check if there are any .log files to compress
if [ -n "$(ls $LOG_DIR/*.log 2>/dev/null)" ]; then
  # Compress .log files into a tar.gz archive with the current date
  tar -czf $LOG_DIR/archive_$(date +%F).tar.gz $LOG_DIR/*.log
  # Remove the compressed .log files
  rm $LOG_DIR/*.log
  echo "[$(date +%F_%T)] Logs compressed and removed." >>$LOG_FILE
else
  echo "[$(date +%F_%T)] No log files found to archive." >>$LOG_FILE
fi

# Keep only the last 5 compressed archives
ls -t $LOG_DIR/archive_*.tar.gz 2>/dev/null | tail -n +6 | xargs rm -f
echo "[$(date +%F_%T)] Cleaned up old archives." >>$LOG_FILE

# Log script end
echo "[$(date +%F_%T)] Script finished." >>$LOG_FILE
