#!/bin/bash

declare -A repos
repos["base"]="rhel-6-server-rpms rhel-6-server-ose-2.2-rhc-rpms rhel-6-server-supplementary-rpms rhel-6-server-optional-rpms rhel-server-rhscl-6-rpms"
repos["broker"]="rhel-6-server-ose-2.2-infra-rpms"
repos["node"]="rhel-6-server-ose-2.2-node-rpms"

username=$1; shift;
password=$1; shift;

# Functions

build_repolist () {
  roles=$@
  local repos_list=${repos["base"]}

  for role in $roles; do
    repos_list="$repos_list ${repos[$role]}"
  done

  echo "$repos_list"
}

build_subscription_string () {
  local repos_list=$(build_repolist $@)
  local subs_string=""

  for repo in ${repos_list}; do
    subs_string="$subs_string --enable=${repo}"
  done

  echo "$subs_string"
}

echo "export PS1=\"[\u@\h <broker> \W]\\$ \"" >> ~/.bash_profile

#TODO: remove password
echo "$username: $password"
subscription-manager register --username=$username --password=$password --auto-attach

subscription-manager repos --disable="*"
echo "Building repolist for: $@"
string=$(build_subscription_string $@)
echo "$string"
subscription-manager repos $string

yum -y update

echo "Please set hostname to the correct value"
