#!/bin/bash

echo "export PS1=\"[\u@\h <broker> \W]\\$ \"" >> ~/.bash_profile

subscription-manager register --auto-attach

subscription-manager repos --disable="*"
subscription-manager repos --enable="rhel-6-server-rpms" --enable="rhel-6-server-ose-2.2-rhc-rpms" --enable="rhel-6-server-supplementary-rpms" --enable="rhel-6-server-optional-rpms" --enable="rhel-server-rhscl-6-rpms" --enable="rhel-6-server-ose-2.2-infra-rpms"

yum -y update

echo "Please set hostname to the correct value"
