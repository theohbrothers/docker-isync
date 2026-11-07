#!/bin/sh
set -eu

if [ "$#" -eq 0 ] || [ "${1#-}" != "$1" ]; then
    set -- mbsync "$@"
fi

exec "$@"
