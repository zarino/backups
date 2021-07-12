#!/bin/sh

set -e -o allexport

HOME="/home/zarino"

. "$HOME/backups/pop/env.conf"

restic init
