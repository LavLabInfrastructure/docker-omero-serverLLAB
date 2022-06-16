#!/bin/bash
#80 LEVEL SCRIPTS ONLY RAN ONCE!
#Creates importer with specified details
initImporter() {
    sleep 30s
    echo "CREATING IMPORTER USER"
    omero login --sudo root -u root -w "${ROOTPASS:? "define ROOTPASS"}" -s localhost -p 4064
    omero group add ${IMPORTGROUP:? "define IMPORTGROUP"}
    omero user add importer OMERO IMPORTER --group-name ${IMPORTGROUP:?} -P "${IMPORTPASS:? "define IMPORTPASS"}"
    touch /OMERO/init.byte
}
#put in background til server starts
initImporter &
