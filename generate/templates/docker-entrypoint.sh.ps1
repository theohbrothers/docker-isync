@'
#!/bin/sh
set -eu

if [ "$#" -eq 0 ] || [ "${1#-}" != "$1" ]; then
    set -- mbsync "$@"
fi

if [ "$1" = 'mbsync' ]; then
    exec "$@"
fi

exec "$@"

'@
