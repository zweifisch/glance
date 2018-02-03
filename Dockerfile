FROM ubuntu:16.04

EXPOSE 9191 9292

RUN apt-get update \
    && apt-get install -y software-properties-common \
    && add-apt-repository -y cloud-archive:pike \
    && apt-get update \
    && apt-get install -y glance python-openstackclient mysql-client \
    && apt-get -y clean

COPY ./glance-api.conf ./glance-registry.conf /etc/glance/
COPY bootstrap.sh /bootstrap.sh

WORKDIR /root
CMD sh -x /bootstrap.sh
