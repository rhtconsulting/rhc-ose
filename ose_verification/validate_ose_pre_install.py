#!/usr/bin/env python2

import socket
from helper_functions import ImportHelper
from deployment_parameters import ParseDeploymentParameters
from ssh_connection_handling import HandleSSHConnections
ImportHelper.import_error_handling("paramiko", globals())
import hashlib

docker_file_dict = {}
forward_lookup_dict = {}
reverse_lookup_dict = {}
ssh_connection = HandleSSHConnections()


def add_to_dictionary(dictionary, name_of_server, component, value):
    if name_of_server in dictionary:
        dictionary[name_of_server][component] = value
    else:
        dictionary[name_of_server] = {component:value}


def process_host_file(ansible_host_file):
    # This section should parse the ansible host file for hosts
    # This doesn't work as it stands because it will suck in variables from the OSE install as well
    # Need a better way to parse the config file

    hosts_list = []
    for line in open(ansible_host_file).readlines():
        if line.startswith("["):
            pass
        else:
            host = line.split()[0]
            hosts_list.append(host)


def test_ssh_keys(host, user):
    """
    test_ssh_keys simply attempts to open an ssh connection to the host
    returns True if the connection throws a Paramiko exception
    """
    try:
        ssh_connection.open_ssh(host, user)
        ssh_connection.close_ssh()
        ssh_connection_failed = False
    except paramiko.ssh_exception.AuthenticationException:
        ssh_connection_failed = True

    return(ssh_connection_failed)


def check_forward_dns_lookup(host_name):
    """
    uses socket to do a forward lookup on host
    returns lookup_passed (True|False) and the host_ip
    """
    try:
        host_ip = socket.gethostbyname(host_name)
        lookup_passwed = True
    except socket.gaierror:
        try:
            socket.inet_aton(host_name)
            print("You should be using FQDN instead of IPs in your ansible host file!")
            pass
        except socket.error:
            pass
        lookup_passed = False
        host_ip = ""

    return(lookup_passed, host_ip)


def check_reverse_dns_lookup(lookup_dict):
    """
    uses socket to do a reverse lookup on hosts in forward_lookup_dict
    returns lookup_passed (True|False) and the hostname
    """
    for hostname in lookup_dict.keys():
        host_ip = lookup_dict[hostname]["ip"]
        try:
            hostname = socket.gethostbyaddr(host_ip)
            lookup_passed = True
        except socket.herror:
            lookup_passed = False
            hostname = ""

    return(lookup_passed, hostname)


def check_docker_files(host, ssh_user):
    """
    check_docker_files assumes there is already a paramiko connection made to the server in question
    """
    file_list = ["/etc/sysconfig/docker", "/etc/sysconfig/docker-storage", "/ect/sysconfig/docker-storage-setup"]
    for files in file_list:
        try:
            ssh_connection.open_ssh(host, ssh_user)
            stdin, stdout, stderr = ssh_connection.ssh.exec_command("sha256sum %s" % files)
            for line in stdout.channel.recv(1024).split("\n"):
                if line.strip():
                    add_to_dictionary(docker_file_dict, host, files, line.split()[0])
        except socket.error:
            print("No SSH connection is open")

# check if docker service is enabled


# check if docker service is started


# check if hosts are subscribed


# check if proper repos are enabled


# check that proper yum packages are installed