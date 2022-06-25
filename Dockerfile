FROM centos:centos7
#install ansible
ADD playbook.yml requirements.yml /opt/setup/
RUN yum -y install epel-release \
    && yum -y install ansible sudo ca-certificates \
    && ansible-galaxy install -p /opt/setup/roles -r /opt/setup/requirements.yml
#install omero/omego
ARG OMERO_VERSION=5.6.4
ARG OMEGO_ADDITIONAL_ARGS=
ENV OMERODIR=/opt/omero/server/OMERO.server/
RUN ansible-playbook /opt/setup/playbook.yml \
    -e omero_server_release=$OMERO_VERSION \
    -e omero_server_omego_additional_args="$OMEGO_ADDITIONAL_ARGS"
#init system
RUN curl -L -o /usr/local/bin/dumb-init \
    https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_x86_64 && \
    chmod +x /usr/local/bin/dumb-init
#add server scripts
ADD entrypoint.sh /usr/local/bin/
ADD 50-config.py 60-database.sh 99-run.sh /startup/
#install server
USER omero-server
RUN cd /opt/omero/server/ && \
    /opt/omero/server/venv3/bin/omego download -q --release 5.6 server --sym auto
USER root
# OMERO.py plugins
RUN /opt/omero/server/venv3/bin/python -m pip install \
    omero-cli-render \
    omero-metadata
#importer
ADD 89-initImporter.sh /startup/
#installation account
USER omero-server
RUN id omero-server
#entry
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
