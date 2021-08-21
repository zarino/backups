#!/bin/sh

set -e -o allexport

SCRIPT_DIR=$(dirname "$0")
HOME="/home/zarino"
PID_FILE="$HOME/.restic_maintain.pid"
TIMESTAMP_FILE="$HOME/.restic_maintain_timestamp"
INTERVAL="2 days" # in a format suitable for passing to `date -d` (GNU date)

. "$SCRIPT_DIR/env.conf"

if [ -f "$PID_FILE" ]; then
  if ps -p $(cat $PID_FILE) > /dev/null; then
    echo $(date +"%Y-%m-%d %T") "File $PID_FILE exists. Maintenance is probably already in progress."
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
echo $(date +"%Y-%m-%d %T") "Maintenance start"

restic --verbose forget --keep-last 10 --keep-daily 7 --keep-weekly 5 --keep-monthly 12 --keep-yearly 3 --prune

echo $(date +"%Y-%m-%d %T") "Maintenance finished"
echo $(date -d "$INTERVAL" +"%s") > $TIMESTAMP_FILE

rm "$PID_FILE"
