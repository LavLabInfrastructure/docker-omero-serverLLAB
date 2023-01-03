#!/bin/bash
#80 LEVEL SCRIPTS ONLY RAN ONCE!
#Creates importer with specified details
initImporter() {
    echo "CREATING IMPORTER USER"
    omero group add ${IMPORTGROUP:? "define IMPORTGROUP"}
    omero user add importer OMERO IMPORTER --group-name ${IMPORTGROUP:?} -P "${IMPORTPASS:? "define IMPORTPASS"}"
    omero logout
    touch /OMERO/init.byte
}
omero login -u root -w "${ROOTPASS:? "define ROOTPASS"}" -s 0.0.0.0 -p 4064 --retry 120 && \
initImporter &
