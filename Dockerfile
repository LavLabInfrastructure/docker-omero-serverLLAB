# OMERO.server on Ubuntu 20 w/ python3.8
FROM amd64/ubuntu:focal

ENV OMERO_DATA_DIR=/OMERO
ENV VENV_SERVER=/opt/omero/server/venv3
ENV OMERODIR=/opt/omero/server/OMERO.server

ENV ICE_HOME=/opt/ice-3.6.5
ENV SLICEPATH="$ICE_HOME/slice"
ENV DEBIAN_FRONTEND=noninteractive

ENV GRAPHITE_TO_PROMETHEUS=false
ENV PROMETHEUS_SERVER=/opt/prometheus-monitor

# prepare apt
USER root
RUN apt update -y && apt upgrade -y && \
    apt install -y apt-utils software-properties-common

# install base packages
RUN apt install -yq unzip \
    curl \
    gnupg \
    python3.8 \
    python3-pip \
    python3-wheel \
    python3.8-venv \
    postgresql-client

# init system
RUN curl -L -o /usr/local/bin/dumb-init \
    https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_x86_64 && \
    chmod +x /usr/local/bin/dumb-init

# install java
RUN add-apt-repository ppa:openjdk-r/ppa && \
    apt update -y && \
    apt install -y openjdk-11-jre

# prepare venv
RUN python3.8 -mvenv "${VENV_SERVER}" && \
    ${VENV_SERVER}/bin/python3.8 -m pip install --upgrade pip wheel

# install ice
WORKDIR /tmp
RUN apt install -yq build-essential \
    db5.3-util \
    libbz2-dev \
    libdb++-dev \
    libdb-dev \
    libexpat-dev \
    libmcpp-dev \
    libssl-dev \
    mcpp \
    zlib1g-dev \ 
    openssl 

RUN curl -L -o /tmp/ice.tar.gz https://github.com/ome/zeroc-ice-ubuntu2004/releases/download/0.2.0/ice-3.6.5-0.2.0-ubuntu2004-amd64.tar.gz 
RUN tar -xf ice.tar.gz && \
    mv ice-3.6.5-0.2.0 /opt/ice-3.6.5 && \
    echo /opt/ice-3.6.5/lib64 > /etc/ld.so.conf.d/ice-x86_64.conf && \
    ldconfig
ENV PATH="${ICE_HOME}/bin:${PATH}"		

# install server prereqs
ENV PATH="${VENV_SERVER}/bin:${PATH}"
RUN useradd -mrp "${ROOTPASS}" -u 1000 omero-server && \
    chmod a+X ~omero-server && \
    mkdir -p "${OMERO_DATA_DIR}"  
RUN $VENV_SERVER/bin/python3.8 -m pip install https://github.com/ome/zeroc-ice-ubuntu2004/releases/download/0.2.0/zeroc_ice-3.6.5-cp38-cp38-linux_x86_64.whl && \
    $VENV_SERVER/bin/python3.8 -m pip install omero-server omero-certificates

# install omero-py and omego
RUN $VENV_SERVER/bin/python3.8 -m pip install omero-py omego


# OMERO.py plugins
RUN $VENV_SERVER/bin/python3.8 -m pip install \
    omero-cli-render \
    omero-cli-duplicate \
    omero-metadata \ 
    omero-upload \
    omero-dropbox \
    omero-rois \
    histoqcxomero \
    tables

# download omero
RUN curl -L -o OMERO.server.zip https://downloads.openmicroscopy.org/omero/latest/server-ice36.zip 
RUN unzip -q OMERO.server.zip && \
    mv OMERO.server-* /opt/omero/server 

# rename server
RUN mv /opt/omero/server/OMERO.server-*/ /opt/omero/server/OMERO.server && \
    ln -s /opt/omero/server/venv3/bin /opt/omero/server/OMERO.server/bin && \
    chown -R omero-server /opt/omero/ /OMERO

# add server scripts
USER omero-server
ADD startup/ /startup/
COPY configs/* /tmp/
COPY --from=prom/graphite-exporter /bin/graphite_exporter /bin/graphite_exporter

# entry
WORKDIR /
# USER root
ENTRYPOINT ["/startup/entrypoint.sh"]
