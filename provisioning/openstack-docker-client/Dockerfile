FROM centos:7

MAINTAINER Andrew Block “andrew.block@redhat.com”

ADD bin/start.sh /root/

# Update System and install clients
RUN yum update -y; \
    yum install -y python-devel epel-release http://rdo.fedorapeople.org/openstack-juno/rdo-release-juno.rpm; \
	yum install -y git tar bind-utils python-pip python-ceilometerclient python-cinderclient python-glanceclient python-heatclient python-neutronclient python-novaclient python-saharaclient python-swiftclient python-troveclient python-openstackclient; \
 	yum clean all
	
# Default Command
CMD ["/bin/bash"]

# Helper script
ENTRYPOINT ["/root/start.sh"]