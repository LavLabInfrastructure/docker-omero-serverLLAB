#!/bin/bash

set -eu
touch /OMERO/init.byte
omero=/opt/omero/server/venv3/bin/omero
cd /opt/omero/server
echo "Starting OMERO.server"
exec $omero admin start --foreground
