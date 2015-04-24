#!/bin/bash
## Environment Setup
PRIVATE_SERVER="172.16.166.14"
PUBLIC_SERVER="10.3.8.181"
SERVERS="${PUBLIC_SERVER} ${PRIVATE_SERVER}"
BASE_DN="ose.example.com"
BASE_NODE_DN="nodes.ose.example.com"
KEY="/var/named/${BASE_DN}.key"
DEFAULT_TIMEOUT=86400

add_A_record() {
  local server=$1
  local name=$2
  local ip=$3
  local ttl=${4:-$DEFAULT_TIMEOUT}
  echo "server ${server}
update add ${name} ${ttl} A ${ip}
send
" | nsupdate -k ${KEY}
}

add_CNAME_record() {
  local server=$1
  local name=$2
  local ref=$3
  local ttl=${4:-$DEFAULT_TIMEOUT}
  echo "server ${server}
update add ${name} ${ttl} CNAME ${ref}
send
" | nsupdate -k ${KEY}
}

add_record() {
  delete_record
  if [ -z $public_ip ]; then
    add_CNAME_record $PRIVATE_SERVER $name $ref_name
    lookup_record $PRIVATE_SERVER $name
    add_CNAME_record $PUBLIC_SERVER $name $ref_name
    lookup_record $PUBLIC_SERVER $name
  else
    add_A_record $PRIVATE_SERVER $name $private_ip
    lookup_record $PRIVATE_SERVER $name
    add_A_record $PUBLIC_SERVER $name $public_ip
    lookup_record $PUBLIC_SERVER $name
  fi
}

delete_record() {
  for server in $PRIVATE_SERVER $PUBLIC_SERVER; do
    delete_A_record $server $name
    delete_CNAME_record $server $name
  done
}

delete_A_record() {
  local server=$1
  local name=$2
  echo "server ${server}
update delete ${name} A
send
" | nsupdate -k ${KEY}
}

delete_CNAME_record() {
  local server=$1
  local name=$2
  echo "server ${server}
update delete ${name} CNAME
send
" | nsupdate -k ${KEY}
}

lookup_record() {
  dig @$1 $2 | grep ^$2
}

usage() {
  echo "Usage: $0 --action {add|delete} --name {dns name} [--public_ip {Public IP Address} --private_ip {Private IP Address}] [--ref_name {CNAME reference}]" 
}

# Process options
while [[ $# -gt 0 ]] &&  [[ ."$1" = .--* ]] ;
do
  opt=$1
  shift
  case "$opt" in
    "--" ) break 2;;
    "--action" )
      action=$1; shift;;
    "--name" )
      name=$1; shift;;
    "--ref_name" )
      ref_name=$1; shift;;
    "--public_ip" )
      public_ip=$1; shift;;
    "--private_ip" )
      private_ip=$1; shift;;
    *) echo >&2 "Invalid option: $@"; exit 1;;
  esac
done

if [ -z $name ]; then
  echo "--name is a required option"
  usage
  exit 1
fi

if [ -z $action ]; then
  echo "--action is a required option"
  usage
  exit 1
elif [ "$action" == "add" ]; then
  add_record
elif [ "$action" == "delete" ]; then
  for server in $SERVERS; do
    delete_A_record $server $name
    lookup_record $server $name
  done
else
  echo "$action is not a valid action."
  exit 1
fi

