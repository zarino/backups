#!/bin/sh

set -ea # allexport and errexit options

SCRIPT=$(basename "$0")
SCRIPT_DIR=$(dirname "$0")
CACHE_DIR="$SCRIPT_DIR/cache"
LOG_DIR="$SCRIPT_DIR/logs"

PID_FILE="$CACHE_DIR/backup.pid"
TIMESTAMP_FILE="$CACHE_DIR/next_backup.timestamp"
LOG_DATE=$(date +"%Y-%m-%d")
LOG_FILE="$LOG_DIR/$LOG_DATE-backup.log"
INCLUDE_FILE="$SCRIPT_DIR/include.conf"
EXCLUDE_FILE="$SCRIPT_DIR/exclude.conf"
INTERVAL="+6H" # in a format suitable for passing to `date -v` (BSD date)
RATE_LIMIT_FLAGS=""

. "$SCRIPT_DIR/env.conf"

log()
{
    echo $(date +"%Y-%m-%d %T") "[$SCRIPT] $@" | tee -a "$LOG_FILE"
}

mkdir -p "$CACHE_DIR"
mkdir -p "$LOG_DIR"

if [ -f "$PID_FILE" ]; then
  if ps -p $(cat $PID_FILE) > /dev/null; then
    log "File $PID_FILE exists. Backup is probably already in progress."
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

if [ -n "$RESTIC_UPLOAD_LIMIT" ]; then
    RATE_LIMIT_FLAGS="$RATE_LIMIT_FLAGS --limit-upload $RESTIC_UPLOAD_LIMIT"
fi
if [ -n "$RESTIC_DOWNLOAD_LIMIT" ]; then
    RATE_LIMIT_FLAGS="$RATE_LIMIT_FLAGS --limit-download $RESTIC_DOWNLOAD_LIMIT"
fi

echo $$ > "$PID_FILE"
log "Backup start"

"${RESTIC_BINARY:-restic}" backup --verbose -o b2.connections=20 --host "$RESTIC_HOST" --files-from "$INCLUDE_FILE" --exclude-file "$EXCLUDE_FILE" $RATE_LIMIT_FLAGS | tee -a "$LOG_FILE"

log "Backup finished"
echo $(date -v "$INTERVAL" +"%s") > $TIMESTAMP_FILE

rm "$PID_FILE"
