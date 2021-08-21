#!/bin/sh

set -e -o allexport

SCRIPT_DIR=$(dirname "$0")
HOME="/home/zarino"
PID_FILE="$HOME/.restic_backup.pid"
TIMESTAMP_FILE="$HOME/.restic_backup_timestamp"
INCLUDE_FILE="$SCRIPT_DIR/include.conf"
EXCLUDE_FILE="$SCRIPT_DIR/exclude.conf"
INTERVAL="6 hours" # in a format suitable for passing to `date -d` (GNU date)

. "$SCRIPT_DIR/env.conf"

if [ -f "$PID_FILE" ]; then
  if ps -p $(cat $PID_FILE) > /dev/null; then
    echo $(date +"%Y-%m-%d %T") "File $PID_FILE exists. Backup is probably already in progress."
    exit 1
  else
    echo $(date +"%Y-%m-%d %T") "File $PID_FILE exists but process " $(cat $PID_FILE) " not found. Removing PID file."
    rm "$PID_FILE"
  fi
fi

if [ -f "$TIMESTAMP_FILE" ]; then
  time_run=$(cat "$TIMESTAMP_FILE")
  current_time=$(date +"%s")

  if [ "$current_time" -lt "$time_run" ]; then
    echo $(date +"%Y-%m-%d %T") "Timestamp in $TIMESTAMP_FILE is still in the future. Skipping."
    exit 2
  fi
fi

echo $$ > "$PID_FILE"
echo $(date +"%Y-%m-%d %T") "Backup start"

restic backup --verbose -o b2.connections=20 --files-from "$INCLUDE_FILE" --exclude-file "$EXCLUDE_FILE"

echo $(date +"%Y-%m-%d %T") "Backup finished"
echo $(date -d "$INTERVAL" +"%s") > $TIMESTAMP_FILE

rm "$PID_FILE"
