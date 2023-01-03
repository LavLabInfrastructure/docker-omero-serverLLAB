#!/usr/local/bin/dumb-init /bin/bash
set -e


source /opt/omero/server/venv3/bin/activate
for f in /startup/*; do
    if [ -f "$f" -a -x "$f" ]; then
	    #if it is an 80 level script we only run it on a fresh container
        [[ "$f" =~ 8[0-9][\-a-zA-Z]+\.[a-zA-Z]+ ]] && \
		    [[ -f /OMERO/init.byte ]] && \
            continue
	    echo "Running $f $@"
        "$f" "$@"
    fi
done
