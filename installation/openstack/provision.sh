openstack_cred=${OPENSTACK_CRED_HOME:-~/.ssh/openstack}
IMAGE_PREFIX="rhel-guest-image-6.5-20140603.0"
rc_file="${openstack_cred}/ec2rc.sh"
interactive="true"

# Functions
usage() {
  echo "Usage: $0 --key {openstack ssh key name} [-n]"
  echo ""
}

# Process options
while [[ $# -gt 0 ]] &&  [[ ."$1" = .--* ]] ;
do
  opt=$1
  shift
  case "$opt" in
    "--" ) break 2;;
    "--key" )
      key="$1"; shift;;
    "--n")
      interactive="false";;
    *) echo >&2 "Invalid option: $@"; exit 1;;
  esac
done

if [ -z $key ]; then
  echo "Missing argument key."
  usage
  exit 1;
fi

# Setup Environment and Gather Requirements
#num_of_brokers=1
#num_of_nodes=1
if [ ! -f $rc_file ]; then
  echo "OpenStack API Credentials not found. Default location is ~/.ssh/openstack/, or set OPENSTACK_CRED_HOME."
  exit 1
fi

. $rc_file

# Provision VMs
image_ami=$(euca-describe-images | awk "/$IMAGE_PREFIX/"'{print $2}')
instance_id=$(euca-run-instances $image_ami -t m1.large -k ${key} | awk '/INSTANCE/ {print $2}')
if [ "$interactive" = "true" ]; then
  echo "Instance ${instance_id} created. Waiting for instance to start..."
fi
count=0
while [ $count -lt 1 ]; do
  count=$(euca-describe-instances $instance_id | grep -c "INSTANCE.*running")
done
instance_ip=$(euca-describe-instances $instance_id | awk '/INSTANCE/ {print $4}')
if [ "$interactive" = "true" ]; then
  echo "Instance IP: ${instance_ip}"
else
  echo "$instance_ip"
fi
