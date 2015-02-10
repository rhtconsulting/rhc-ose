OPENSTACK_CREDS_HOME=${openstack_cred:-~/.ssh/openstack/}
IMAGE_PREFIX=rhel-guest-image-6.5-20140603.0

# Setup Environment and Gather Requirements
#num_of_brokers=1
#num_of_nodes=1
. ${OPENSTACK_CREDS_HOME}/ec2

# Provision VMs
image_ami=$(euca-describe-images | awk '/$IMAGE_PREFIX/ {print $2}')
instance_id=$(euca-run-instances $image_ami -t m1.tiny -k lxplus | awk '/INSTANCE/ {print $2}')
instance_ip=$(euca-describe-instances $instance_id | awk '/INSTANCE/ {print $4}')
echo "Instance IP: ${instance_ip}"
