#!/bin/sh

set -e -o allexport

SCRIPT_DIR=$(dirname "$0")

. "$SCRIPT_DIR/env.conf"

restic "$@"
