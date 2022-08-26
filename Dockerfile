# OMERO.server on Ubuntu 20 w/ python3.8
FROM ubuntu:focal

ENV VENV_SERVER=/opt/omero/server/venv3
ENV ICE_HOME=/opt/ice-3.6.5
ENV SLICEPATH="$ICE_HOME/slice"
ENV OMERODIR=/opt/omero/server/OMERO.server
ENV OMERO_DATA_DIR=/OMERO

USER root
RUN apt update -y && apt upgrade -y && \
    apt install -y unzip curl python3 python3-venv software-properties-common && \
    apt install -y postgresql

#init system
RUN curl -L -o /usr/local/bin/dumb-init \
    https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_x86_64 && \
    chmod +x /usr/local/bin/dumb-init

# install java
RUN add-apt-repository ppa:openjdk-r/ppa && \
    apt update -y && \
    apt install -y openjdk-11-jre

# install ice
RUN apt install -y build-essential \
    db5.3-util \
    libbz2-dev \
    libdb++-dev \
    libdb-dev \
    libexpat-dev \
    libmcpp-dev \
    libssl-dev \
    mcpp \
    zlib1g-dev
WORKDIR /tmp
RUN curl -L -o /tmp/ice.tar.gz https://github.com/ome/zeroc-ice-ubuntu2004/releases/download/0.2.0/ice-3.6.5-0.2.0-ubuntu2004-amd64.tar.gz 
RUN tar -xf ice.tar.gz && \
    mv ice-3.6.5-0.2.0 /opt/ice-3.6.5 && \
    echo /opt/ice-3.6.5/lib64 > /etc/ld.so.conf.d/ice-x86_64.conf && \
    ldconfig
ENV PATH="${ICE_HOME}/bin:${PATH}"		

#install server prereqs
ENV PATH="${VENV_SERVER}/bin:${PATH}"
RUN useradd -mrp "${ROOTPASS}" -u 1000 omero-server && \
    chmod a+X ~omero-server && \
    mkdir -p "${OMERO_DATA_DIR}"  
RUN python3 -mvenv "${VENV_SERVER}" && \
    $VENV_SERVER/bin/pip install https://github.com/ome/zeroc-ice-ubuntu2004/releases/download/0.2.0/zeroc_ice-3.6.5-cp38-cp38-linux_x86_64.whl && \
    $VENV_SERVER/bin/pip install omero-server

# install omero-py and omego
RUN $VENV_SERVER/bin/pip install omero-py>=5.8.0 omego

# OMERO.py plugins
RUN $VENV_SERVER/bin/pip install \
    omero-cli-render \
    omero-metadata \ 
    histoqcxomero \
    tables

#download omero
RUN curl -L -o OMERO.server.zip https://downloads.openmicroscopy.org/omero/5.6/server-ice36.zip 
RUN unzip -q OMERO.server.zip && \
    mv OMERO.server-* /opt/omero/server 

#install omero
WORKDIR /opt/omero/server
RUN ln -s OMERO.server-*/ OMERO.server && \
    ln -s venv3/bin OMERO.server/bin && \
    chown -R omero-server . && \
    chown -R omero-server "${OMERO_DATA_DIR}"

#add server scripts
USER omero-server
RUN omero certificates 
ADD entrypoint.sh /usr/local/bin/
ADD 50-config.py 60-database.sh 89-initImporter.sh 99-run.sh /startup/
#entry
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
