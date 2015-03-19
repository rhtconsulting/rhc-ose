# Functions
usage() {
  echo "Usage: $0 --key <openstack ssh key name> --instance-name <name> [--rhel7] [-n] [--auth-key-file <file location>]"
  echo ""
}

wait_for_instance_running() {
  local instance_name=$1

  command="[ \$( nova show $instance_name | grep -c \"status.*ACTIVE\" ) -eq 1 ]"
  run_cmd_with_timeout "$command" ${2:-30}
}

wait_for_ssh() {
  local instance_ip=$1

  command="ssh -o StrictHostKeyChecking=no cloud-user@${instance_ip} 'ls' &>/dev/null"
  run_cmd_with_timeout "$command" ${2:-60}
}

run_cmd_with_timeout() {
  local command="$1"
  local timeout=$2

  next_wait_time=0
  until eval "$command" || [ $next_wait_time -eq $timeout ]; do
    sleep $(( next_wait_time++ ))
  done
  [ $next_wait_time -eq $timeout ] && echo "Command $command timed out after $timeout seconds."
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
    "--instance-name")
      instance_name="$1"; shift;;
    "--rhel7")
      image_name="rhel-guest-image-7.0-20140618.1";;
    "--auth-key-file")
      options="${options} --file /root/.ssh/authorized_keys=$1"; shift;;
    *) echo >&2 "Invalid option: $@"; exit 1;;
  esac
done

if [ -z $key ] || [ -z $instance_name ]; then
  echo "Missing argument key."
  usage
  exit 1;
fi

# Setup Environment and Gather Requirements
openstack_cred=${OPENSTACK_CRED_HOME:-~/.openstack/openrc.sh}
image_name_search=${image_name:-"rhel-guest-image-6.5-20140603.0"}
rc_file="${openstack_cred}"
interactive="true"
#security_groups="default,osebroker,osenode"
security_groups="default"
flavor="m1.large"
#num_of_brokers=1
#num_of_nodes=1
if [ ! -f $rc_file ]; then
  echo "OpenStack API Credentials not found. Default location is ${rc_file}, or set OPENSTACK_CRED_HOME."
  exit 1
fi

if [ -z $security_groups ]; then
  options="${options} --security-groups ${security_groups}"

. $rc_file

# Provision VMs
image_ami=$(nova image-list | awk "/$image_name_search/"'{print $2}')
echo "nova boot --image ${image_ami} --flavor ${flavor} --key-name ${key} ${options} ${instance_name}"
status=$(nova boot --image ${image_ami} --flavor ${flavor} --key-name ${key} ${options} ${instance_name} | awk '/status/ {print $4}')
if [ "$status" != "BUILD" ]; then
  echo "Something went wrong during image creation."
  echo "Status expected: BUILD"
  echo "Status received: $status"
  exit 1
fi

if [ "$interactive" = "true" ]; then
  echo "Instance ${instance_name} created. Waiting for instance to start..."
fi

# need to wait for instance to be in running state
wait_for_instance_running $instance_name

if [ "$interactive" = "true" ]; then
  echo "Instance ${instance_name} is active. Waiting for ssh service to be ready..."
fi

instance_ip=$(nova show $instance_name | awk '/os1-internal.*network/ {print $6}')

# need to wait until ssh service comes up on instance
wait_for_ssh $instance_ip

if [ "$interactive" = "true" ]; then
  echo "Instance IP: ${instance_ip}"
else
  echo "$instance_ip"
fi
