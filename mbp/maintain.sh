#!/bin/sh

set -ea # allexport and errexit options

SCRIPT=$(basename "$0")
SCRIPT_DIR=$(dirname "$0")
CACHE_DIR="$SCRIPT_DIR/cache"
LOG_DIR="$SCRIPT_DIR/logs"

PID_FILE="$CACHE_DIR/maintain.pid"
TIMESTAMP_FILE="$CACHE_DIR/next_maintain.timestamp"
LOG_DATE=$(date +"%Y-%m-%d")
LOG_FILE="$LOG_DIR/$LOG_DATE-maintain.log"
INTERVAL="+48H" # in a format suitable for passing to `date -v` (BSD date)

. "$SCRIPT_DIR/env.conf"

log()
{
    echo $(date +"%Y-%m-%d %T") "[$SCRIPT] $@" | tee -a "$LOG_FILE"
}

mkdir -p "$CACHE_DIR"
mkdir -p "$LOG_DIR"

if [ -f "$PID_FILE" ]; then
  if ps -p $(cat $PID_FILE) > /dev/null; then
    log "File $PID_FILE exists. Maintenance is probably already in progress."
    exit 1
  else
    log "File $PID_FILE exists but process " $(cat $PID_FILE) " not found. Removing PID file."
    rm "$PID_FILE"
  fi
fi

if [ -f "$TIMESTAMP_FILE" ]; then
  time_run=$(cat "$TIMESTAMP_FILE")
  current_time=$(date +"%s")

  if [ "$current_time" -lt "$time_run" ]; then
    log "Timestamp in $TIMESTAMP_FILE is still in the future. Skipping."
    exit 2
  fi
fi

if [ $(pmset -g ps | head -1 | grep -c "Battery") -gt 0 ]; then
  log "Computer is not connected to the power source."
  exit 4
fi

echo $$ > "$PID_FILE"
log "Maintenance start"

"${RESTIC_BINARY:-restic}" forget --verbose --keep-last 10 --keep-daily 7 --keep-weekly 5 --keep-monthly 12 --keep-yearly 3 --prune | tee -a "$LOG_FILE"

log "Maintenance finished"
echo $(date -v "$INTERVAL" +"%s") > $TIMESTAMP_FILE

rm "$PID_FILE"
