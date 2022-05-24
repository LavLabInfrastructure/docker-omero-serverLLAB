FROM centos:centos7
#
ADD playbook.yml requirements.yml /opt/setup/
RUN yum -y install epel-release \
    && yum -y install ansible sudo ca-certificates \
    && ansible-galaxy install -p /opt/setup/roles -r /opt/setup/requirements.yml
ARG OMERO_VERSION=5.6.4
ARG OMEGO_ADDITIONAL_ARGS=
ENV OMERODIR=/opt/omero/server/OMERO.server/
RUN ansible-playbook /opt/setup/playbook.yml \
    -e omero_server_release=$OMERO_VERSION \
    -e omero_server_omego_additional_args="$OMEGO_ADDITIONAL_ARGS"
RUN curl -L -o /usr/local/bin/dumb-init \
    https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_x86_64 && \
    chmod +x /usr/local/bin/dumb-init
ADD entrypoint.sh /usr/local/bin/
ADD 50-config.py 99-run.sh /startup/
USER omero-server
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
