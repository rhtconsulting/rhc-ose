FROM centos:7

MAINTAINER Andrew Block “andrew.block@redhat.com”

ADD bin/start.sh /root/

# Update System and install clients
RUN yum install -y https://repos.fedorapeople.org/repos/openstack/openstack-liberty/rdo-release-liberty-3.noarch.rpm; \
  yum update -y; \
  yum install -y python-devel epel-release; \
	yum install -y git tar bind-utils ansible1.9 python-pip python-ceilometerclient python-cinderclient python-glanceclient python-heatclient python-neutronclient python-novaclient python-saharaclient python-swiftclient python-troveclient python-openstackclient python-passlib; \
 	yum clean all

# Set /root as starting directory
WORKDIR /root

# Default Command
CMD ["/bin/bash"]

# Helper script
ENTRYPOINT ["/root/start.sh"]
