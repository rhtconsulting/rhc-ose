# Functions
usage() {
  echo "
Usage: $0 --action <boot|delete_by_name|delete_by_ip> [options]

Options:
  --action <action>                   : Action to execute -- boot, delete (default: boot)
  --instance-name <name>              : *Name of your instance
  --key <openstack ssh key name>      : *Name of your SSH key in OpenStack dashboard.
  --image-name <image-name>           : Specify an image (or snapshot) to use for boot
  --auth-key-file <file location>     : Pass a custom authorized keys file to the root user (for multiple user access).
  --security-groups <security groups> : Specift security groups for your instance
  --num-instances <number>            : Number of instances to create with this profile
  --add-volume <size>                 : Add a volume of a given size (in GB)
  --debug                             : Set log level to Debug
  --n                                 : non-iteractive mode for use with scripts. Doesn't log anything to the console
  "

}

# Usage: attach_volume <name> <size (in GB)>
attach_volume() {
  # Create Volume
  volume_info="$(nova volume-create --display-name ${1} ${2})"
  volume_id=$(echo "$volume_info" | awk '/ id / {print $4}')
  creating=$(echo "$volume_info" | awk '/status/ {print $4}')
  if [ "$creating" != "creating" ]; then
    safe_out "error" "Volume create failed."
    exit 2
  fi

  # Wait for it to be available
  available_command="[ \$( nova volume-show ${volume_id} | grep -cE \"status.*available\" ) -eq 1 ]"
  run_cmd_with_timeout "$available_command" 20

#  volume_info="$( cinder show ${volume_id})"
#  status=$(echo "$volume_info" | awk '/status/ {print $4}')

  # Attach volume to instance
  attached="$(nova volume-attach ${1} ${volume_id} /dev/vdb | awk '/ id / {print $4}')"
  if [ $? -ne 0 ]; then
    safe_out "error" "Failed to attach volume"
    exit 2
  fi

}

do_boot() {
  boot_servers
}

do_delete_by_ip() {
  delete_servers_by_ip $IP_ADDRESSES
}

do_delete_by_name() {
  required_args="instance-name:$instance_name"
  validate_args "$required_args"
  delete_servers $instance_name
}

boot_servers() {
  required_args="key:$key instance-name:$instance_name"
  validate_args "$required_args"

  # Provision VMs
  image_ami=$(nova image-list | awk "/$image_name_search/"'{print $2}')
  [ $(echo "$image_ami" | grep -c ".*") != 1 ] && safe_out "error" "--image-name $image_name_search gave multiple matches. Be more specific" && exit 2

  safe_out "debug" "nova boot --image ${image_ami} --flavor ${flavor} --key-name ${key} ${options} ${instance_name}"
  instance_status=$(nova boot --image ${image_ami} --flavor ${flavor} --key-name ${key} ${options} ${instance_name} | awk '/^\| id/ || /^\| status/ {print $4}')
  safe_out "debug" "${instance_status}"
  instance_status=${instance_status//$'\n'/ }
  instance_id=${instance_status%' '*}
  status=${instance_status#*' '}

  if [ "$status" != "BUILD" ]; then
    echo "Something went wrong during image creation."
    echo "Status expected: BUILD"
    echo "Status received: $status"
    exit 1
  fi

  # added to support multiple instances
  instance_ids=$(nova list --name ${instance_name} | awk "/${instance_name}/"'{print $2}')

  for instance_id in ${instance_ids//$'\n'/ }; do

    instance_name=$(nova show $instance_id | awk "/ name/"'{print $4}')

    # need to wait for instance to be in running state
    wait_for_instance_running $instance_id
    safe_out "info" "Instance ${instance_name} is active. Waiting for ssh service to be ready..."
    instance_ip=$(nova show ${instance_id} | awk '/os1-internal.*network/ {print $5$6}')

    # need to wait until ssh service comes up on instance
    wait_for_ssh ${instance_ip#*,} 120

    if [ -n "$volume_size" ]; then
      safe_out "info" "Adding a Volume"
      attach_volume $instance_id $volume_size
    fi

    safe_out "info" "Instance ${instance_name} is accessible and ready to use."

    if [ "$interactive" = "true" ]; then
      echo "Instance IP: ${instance_ip//,/|}"
    else
      echo "${instance_ip//,/|}"
    fi

  done

}

delete_servers() {
  server_name=$1
  max_servers=6
  # Ensure we have a decently non-generic server_name to search with, so that we don't match too many instances
  [ ${#server_name} -lt 8 ] && error_out "Server name is too short. Risk of deleting too many servers." $ERROR_CODE_PROVISION_FAILURE
  servers=$(nova list | awk "/$server_name/"'{print $2}' | sed ':a;N;$!ba;s/\n/ /g')

  # Another safety check to make sure we're deleting a reasonable number of instances
  if [ $(echo "$servers" | wc -w) -gt $max_servers ]; then
    error_out "More than $max_servers. Please double check your instance-name: $server_name" $ERROR_CODE_PROVISION_FAILURE
  elif [ $(echo "$servers" | wc -w) -le 0 ]; then
    error_out "No servers match your instance-name." $ERROR_CODE_PROVISION_FAILURE
  fi

  # Before we delete, we need to grab the volumes attached.
  volumes="$(nova volume-list)"
  volumes_to_delete=""
  for server in $servers; do
    volumes_to_delete="$volumes_to_delete $(echo "$volumes" | awk "/$server/"'{print $2}')"
  done

  nova delete $servers && safe_out "info" "Deleted servers: $servers"

  if [ -n "${volumes_to_delete// /}" ]; then
    for volume in $volumes_to_delete; do
      wait_for_volume_detached $volume
    done
    nova volume-delete $volumes_to_delete && safe_out "info" "Deleted volumes: $volumes_to_delete"
  fi
}

delete_servers_by_ip() {
  ip_addrs=$1
  [ -z $ip_addrs ] && echo "Missing argument: --ips <ip1,ip2,...ipN>" && exit 1

  for ip in ${ip_addrs//,/ }; do
    servers="$servers $(nova list | awk "/$ip/"'{print$2}')"
  done
  delete_servers $servers
}

# Usage: error_out <message> <error_code>
error_out() {
  safe_out "error" "${1}"
  exit $2
}

get_fault_info() {
  local instance_info="$1"

  echo "$instance_info" | grep '^| fault'
  safe_out "debug" "$instance_info"
}

validate_args() {
  for arg in $1; do
    if [ -z ${arg#*:} ]; then
      echo "Missing argument --${arg%:*}."
      usage
      exit 1;
    fi
  done

}

wait_for_instance_running() {
  local instance_name=$1

  safe_out "info" "Instance ${instance_name} created. Waiting for instance to start..."

  command="[ \$( nova show $instance_name | grep -cE \"status.*ACTIVE|status.*ERROR\" ) -eq 1 ]"
  run_cmd_with_timeout "$command" ${2:-30}

  instance_info="$(nova show $instance_name)"
  status=$( echo "$instance_info" | awk '/status/ {print $4}' )
  if [ "$status" == "ERROR" ]; then
    safe_out "error" "Instance $instance_name failed to boot:"
    safe_out $(get_fault_info "$instance_info")
    exit 2
  fi
}

wait_for_ssh() {
  local instance_ip=$1

  command="ssh -o StrictHostKeyChecking=no root@${instance_ip} 'ls' &>/dev/null"
  run_cmd_with_timeout "$command" ${2:-60}
}

wait_for_volume_detached() {
  local volume=$1

  command="[ \$( nova volume-show $volume | grep -cE \"status.*available|status.*error\" ) -eq 1 ]"
  run_cmd_with_timeout "$command" ${2:-30}
}

run_cmd_with_timeout() {
  local command="$1"
  local timeout=$2

  next_wait_time=0
  until eval "$command" || [ $next_wait_time -eq $timeout ]; do
    safe_out "debug" "Ran command at $next_wait_time: $command"
    sleep 1
    ((next_wait_time++))
  done
  [ $next_wait_time -eq $timeout ] && error_out "Command $command timed out after $timeout seconds." 11
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
action="boot"
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
    "--action")
      action=$1; shift;;
    "--add-volume")
      volume_size=$1; shift;;
    "--instance-name")
      instance_name="$1"; shift;;
    "--image-name")
      image_name="$1"; shift;;
    "--ips")
      IP_ADDRESSES="$1"; shift;;
    "--auth-key-file")
      auth_key_file=true;
      options="${options} --file /root/.ssh/authorized_keys=$1";
      shift;;
    "--security-groups")
      options="${options} --security-groups $1";
      shift;;
    "--num-instances")
      num_instances=$1;
      shift;;
    "--debug")
      LOG_LEVEL="debug";;
    *) echo >&2 "Invalid option: $@"; exit 1;;
  esac
done

# Setup Environment and Gather Requirements
openstack_cred=${OPENSTACK_CRED_HOME:-~/.openstack/openrc.sh}
image_name_search=${image_name:-"rhel-guest-image-7.0-20140618.1"}
rc_file="${openstack_cred}"
flavor="m1.large"
if [ ! -f $rc_file ]; then
  safe_out "error" "OpenStack API Credentials not found. Default location is ${rc_file}, or set OPENSTACK_CRED_HOME."
  exit 1
fi

if [ ! -z $num_instances ]; then
  options="${options} --num-instances ${num_instances}"
fi

. $rc_file

if [ "$interactive" = "true" ]; then
  echo "Tail Logfile for More Info: ${LOGFILE}"
fi

actions="boot delete_by_ip delete_by_name"

if [[ $actions =~ (^| )$action($| ) ]]; then
  do_$action
else
  echo "Invalid value for --action: $action"
  echo "Valid actions: $actions"
  exit 1
fi
