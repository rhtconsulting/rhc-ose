#FROM centos:7
FROM openshift/base-centos7
MAINTAINER tim@timhunt.net

ENV SQUID_VERSION=3.3.8

# Set labels used in OpenShift to describe the builder images
LABEL io.k8s.description="Squid http proxy" \
      io.k8s.display-name="Squid 3.3.8" \
      io.openshift.expose-services="3128:3128" \
      io.openshift.tags="squid,http,proxy"

RUN yum -q -y update \
 && yum -q -y install squid \
 && yum -q -y --enablerepo=* clean all

COPY squid.conf /etc/squid/squid.conf
COPY entrypoint.sh /entrypoint.sh

RUN chmod 755 /entrypoint.sh && \
    chmod 777 /etc/squid /var/log/squid /var/run /var/run/squid /var/spool/squid && \
    chmod 666 /etc/squid/squid.conf

USER 1001

EXPOSE 3128/tcp

ENTRYPOINT ["/entrypoint.sh"]
