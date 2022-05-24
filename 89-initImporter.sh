#!/bin/bash
#80 LEVEL SCRIPTS ONLY RAN ONCE!
#Creates importer with specified details
initImporter() {
    sleep 2m
    echo "CREATING IMPORTER USER"
    omero login --sudo root -u root -w "${ROOTPASS:? "define ROOTPASS"}" -s localhost -p 4064
    omero group add ${IMPORTGROUP:? "define IMPORTGROUP"}
    omero user add importer OMERO IMPORTER --group-name ${IMPORTGROUP:?} -P "${IMPORTPASS:? "define IMPORTPASS"}"
}
#folder should be created by dockercompose (if using dropbox)
if [[ -d "/OMERO/DropBox/importer" ]]; then
	#put in background til server starts
	initImporter &
fi
