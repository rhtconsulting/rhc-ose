# Functions
usage() {
  echo "
Usage: $0 --instance-name <name> --key <key name>[options]

Options:
  --instance-name <name>              : *Name of your instance
  --key <openstack ssh key name>      : *Name of your SSH key in OpenStack dashboard.
  --image-name <image-name>           : Specify an image (or snapshot) to use for boot
  -n                                  : non-iteractive mode for use with scripts. Doesn't log anything to the console
  --auth-key-file <file location>     : Pass a custom authorized keys file to the root user (for multiple user access).
  --security-groups <security groups> : Specift security groups for your instance
  --debug                             : Set log level to Debug
  "

}

get_fault_info() {
  local instance_info="$1"

  echo "$instance_info" | grep '^| fault'
  safe_out "debug" "$instance_info"
}

wait_for_instance_running() {
  local instance_name=$1

  command="[ \$( nova show $instance_name | grep -cE \"status.*ACTIVE|status.*ERROR\" ) -eq 1 ]"
  run_cmd_with_timeout "$command" ${2:-30}

  instance_info="$(nova show $instance_name)"
  status=$( echo "$instance_info" | awk '/status/ {print $4}' )
  [ "$status" == "ERROR" ] && safe_out "error" "Instance $instance_name failed to boot:"
  [ "$status" == "ERROR" ] && get_fault_info "$instance_info"
  [ "$status" == "ERROR" ] && exit 2
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
    safe_out "debug" "Ran command at $next_wait_time: $command"
    sleep $(( next_wait_time++ ))
  done
  [ $next_wait_time -eq $timeout ] && safe_out "error" "Command $command timed out after $timeout seconds."
}

safe_out() {
  [ "$1" == "debug" ] && [ "${LOG_LEVEL}" == "debug" ] && log "$1" "$2"
  [ "$1" == "info" ] && ([ "${LOG_LEVEL}" == "info" ] || [ "${LOG_LEVEL}" == "debug" ]) && log "$1" "$2"
  [ "$1" == "error" ] && log "$1" "$2"
}

log() {
  echo "$(date): $1: $2" >> $LOGFILE
}

# Initialize environment
interactive="true"
LOGFILE=~/openstack_provision.log
LOG_LEVEL="info"

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
      unset interactive;;
    "--instance-name")
      instance_name="$1"; shift;;
    "--image-name")
      image_name="$1"; shift;;
    "--auth-key-file")
      auth_key_file=true;
      options="${options} --file /root/.ssh/authorized_keys=$1";
      shift;;
    "--security-groups")
      options="${options} --security-groups=$1";
      shift;;
    "--debug")
      LOG_LEVEL="debug";;
    *) echo >&2 "Invalid option: $@"; exit 1;;
  esac
done

for arg in "key:$key" "instance-name:$instance_name"; do
  if [ -z ${arg#*:} ]; then
    echo "Missing argument --${arg%:*}."
    usage
    exit 1;
  fi
done

# Setup Environment and Gather Requirements
openstack_cred=${OPENSTACK_CRED_HOME:-~/.openstack/openrc.sh}
image_name_search=${image_name:-"rhel-guest-image-7.0-20140618.1"}
rc_file="${openstack_cred}"
#security_groups="default,osebroker,osenode"
security_groups="default"
flavor="m1.large"
#num_of_brokers=1
#num_of_nodes=1
if [ ! -f $rc_file ]; then
  safe_out "error" "OpenStack API Credentials not found. Default location is ${rc_file}, or set OPENSTACK_CRED_HOME."
  exit 1
fi

if [ -z $security_groups ]; then
  options="${options} --security-groups ${security_groups}"
fi

. $rc_file

if [ "$interactive" = "true" ]; then
  echo "Tail Logfile for More Info: ${LOGFILE}"
fi

# Provision VMs
image_ami=$(nova image-list | awk "/$image_name_search/"'{print $2}')
[ $(echo "$image_ami" | grep -c ".*") != 1 ] && safe_out "error" "--image-name $image_name_search gave multiple matches. Be more specific" && exit 2

safe_out "debug" "nova boot --image ${image_ami} --flavor ${flavor} --key-name ${key} ${options} ${instance_name}"
instance_status=$(nova boot --image ${image_ami} --flavor ${flavor} --key-name ${key} ${options} ${instance_name} | awk '/^\| id/ || /^\| status/ {print $4}')
instance_status=${instance_status//$'\n'/ }
instance_id=${instance_status%' '*}
status=${instance_status#*' '}

if [ "$status" != "BUILD" ]; then
  echo "Something went wrong during image creation."
  echo "Status expected: BUILD"
  echo "Status received: $status"
  exit 1
fi

safe_out "info" "Instance ${instance_name} created. Waiting for instance to start..."

# need to wait for instance to be in running state
wait_for_instance_running $instance_id

safe_out "info" "Instance ${instance_name} is active. Waiting for ssh service to be ready..."

instance_ip=$(nova show $instance_id | awk '/os1-internal.*network/ {print $6}')

# need to wait until ssh service comes up on instance
wait_for_ssh $instance_ip

safe_out "info" "Instance ${instance_name} is accessible and ready to use."

if [ "$interactive" = "true" ]; then
  echo "Instance IP: ${instance_ip}"
else
  echo "$instance_ip"
fi
