#!/bin/bash

echo "export PS1=\"[\u@\h <broker> \W]\\$ \"" >> ~/.bash_profile

subscription-manager register --auto-attach

yum -y yum-utils

yum-config-manager --disable "*"
yum-config-manager --enable rhel-6-server-rpms rhel-6-server-ose-2.2-rhc-rpms rhel-6-server-supplementary-rpms rhel-6-server-optional-rpms rhel-server-rhscl-6-rpms rhel-6-server-ose-2.2-infra-rpms

yum -y update

echo "Please set hostname to the correct value"
