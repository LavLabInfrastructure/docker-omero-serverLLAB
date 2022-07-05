FROM centos:centos7.9.2009@sha256:c73f515d06b0fa07bb18d8202035e739a494ce760aa73129f60f4bf2bd22b407
LABEL maintainer="ome-devel@lists.openmicroscopy.org.uk"
LABEL org.opencontainers.image.created="unknown"
LABEL org.opencontainers.image.revision="unknown"
LABEL org.opencontainers.image.source="https://github.com/openmicroscopy/omero-server-docker"

RUN mkdir /opt/setup
WORKDIR /opt/setup
ADD playbook.yml requirements.yml /opt/setup/
RUN yum -y install epel-release \
    && yum -y install ansible sudo ca-certificates \
    && ansible-galaxy install -p /opt/setup/roles -r requirements.yml \
    && yum -y clean all \
    && rm -fr /var/cache
#install omero
ARG OMERO_VERSION=5.6.5
ARG OMEGO_ADDITIONAL_ARGS=
ENV OMERODIR=/opt/omero/server/OMERO.server/
RUN ansible-playbook /opt/setup/playbook.yml \
    -e omero_server_release=$OMERO_VERSION \
    -e omero_server_omego_additional_args="$OMEGO_ADDITIONAL_ARGS" \
    && yum -y clean all \
    && rm -fr /var/cache
#init system
RUN curl -L -o /usr/local/bin/dumb-init \
    https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_x86_64 && \
    chmod +x /usr/local/bin/dumb-init
#add server scripts
ADD entrypoint.sh /usr/local/bin/
ADD 50-config.py 60-database.sh 89-initImporter.sh 99-run.sh /startup/
#install server
USER omero-server
RUN cd /opt/omero/server/ && \
    /opt/omero/server/venv3/bin/omego download -q --release 5.6 server --sym auto
USER root
# OMERO.py plugins
RUN /opt/omero/server/venv3/bin/python -m pip install \
    omero-cli-render \
    omero-metadata
#installation account
USER omero-server
RUN id omero-server
#entry
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
