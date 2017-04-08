FROM centos:7

MAINTAINER Eric Sauer “esauer@redhat.com”

ADD bin/start.sh /root/

# Update System and install clients
RUN yum update -y; \
    yum install -y python-devel epel-release http://rdo.fedorapeople.org/openstack-juno/rdo-release-juno.rpm; \
	yum install -y git tar bind-utils ansible python-pip ansible python-boto pyOpenSSL; \
 	yum clean all

# Set /root as starting directory
WORKDIR /root

# Default Command
CMD ["/bin/bash"]

# Helper script
ENTRYPOINT ["/root/start.sh"]
