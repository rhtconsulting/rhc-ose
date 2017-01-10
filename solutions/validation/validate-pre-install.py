#!/usr/bin/env python2
# Owner: Steve Ovens
# Date Created: March 2016
# Primary Function: This script will do basic verification required for OSE installs to be successful
# It will do nothing if called directly.
# Dependencies: helper_functions.py, ssh_connection_handling.py
# This script has some tight coupling to helper_functions DictionaryHandling particularly when it
# comes to adding objects to dictionaries.


import socket
from helper_functions import DictionaryHandling
from helper_functions import ImportHelper
from helper_functions import textColors
from ssh_connection_handling import HandleSSHConnections
import yum
import sys
from optparse import OptionParser

ImportHelper.import_error_handling("paramiko", globals())


ansible_ssh_user = "root"
docker_files_have_been_modified_dict = {}
remote_docker_file_sums_dict = {}
docker_service_check_dict = {}
# These may need to be updated occasionally in the event that the default options change
original_docker_file_hashes = \
           {"/etc/sysconfig/docker": "1fe04a24430eaefb751bf720353e730aec5641529f0a3b2567f72e6c63433e8b",
            "/etc/sysconfig/docker-storage": "709dca62ac8150aa280fdb4d49d122d78a6a2f4f46ff3f04fe8d698b7035f3a0",
            "/etc/sysconfig/docker-storage-setup": "bf3e1056e8df0dd4fc170a89ac2358f872a17509efa70a3bc56733a488a1e4b2"}

forward_lookup_dict = {}
reverse_lookup_dict = {}
repo_dict = {}
package_updates_available_dict = {}
subscription_dict = {}
ose_package_installed_dict = {}
ose_package_not_installed_dict = {}
ssh_connection = HandleSSHConnections()
selinux_dict = {}
ose_repos = ["rhel-7-server-rpms", "rhel-7-server-extras-rpms", "rhel-7-server-ose-3.1-rpms"]
ose_required_packages_list = ["wget", "git", "net-tools", "bind-utils", "iptables-services", "bridge-utils",
                              "bash-completion", "atomic-openshift-utils", "docker"]

# OptionParser's first argument is what is passed in on the command line.
# the second argument 'dest=' is the variable which holds the value. options.show_sha_sums holds the value for
# --show-sha-sums.
# The final arugment is the text that is printed out when the OptionParser help function is called
parser = OptionParser()
parser.add_option('--ansible-host-file', dest='ansible_host_file', help='Specify location of ansible hostfile')
parser.add_option('--show-sha-sums', dest='show_sha_sums', help='Toggle whether or not to show the sha sum of files'
                                                                'on remote host')
(options, args) = parser.parse_args()


def is_selinux_enabled(host, ssh_obj, dict_to_modify):
    """
    is_selinux_enabled logs into the remote host and runs/parses 'sestatus'
    adds results to a dictionary
    """
    output = HandleSSHConnections.run_remote_commands(ssh_obj, "sestatus")
    for line in output:
        if "SELinux status" in line:
            if "enabled" in line:
                DictionaryHandling.add_to_dictionary(dict_to_modify, host, "SELinux Enabled", True)
            else:
                DictionaryHandling.add_to_dictionary(dict_to_modify, host, "SELinux Enabled", False)


def process_host_file(ansible_host_file):
    # This section should parse the ansible host file for hosts
    # This parses the host file with a similar format to ini files
    # TODO: Need a better way to parse the config file
    hosts_list = []
    for line in open(ansible_host_file).readlines():
        # Skip section headings
        if line.startswith("["):
            pass
        # Skip comments
        elif line.startswith("#"):
            pass
        # Skip blank lines
        elif not line.strip():
            pass
        # We don't care about lines doing assignments generally speaking.
        # There is room for error with this method
        elif "=" in line.split()[0]:
            pass
        else:
            host = line.split()[0]
            # I am assuming that FQDN's are being used, this is a work-around for distinguishing
            # between ansible children, vars and actual hostnames
            if "." in host:
                if not host in hosts_list:
                    hosts_list.append(host)
    return(hosts_list)


def test_ssh_keys(host, user):
    """
    test_ssh_keys simply attempts to open an ssh connection to the host
    returns True if the connection is accepted and False if Paramiko throws an exception
    """
    try:
        ssh_connection.open_ssh(host, user)
        ssh_connection.close_ssh()
        ssh_connection_succeed = True
    except (paramiko.ssh_exception.AuthenticationException, socket.gaierror):
        ssh_connection_succeed = False

    return(ssh_connection_succeed)


def check_forward_dns_lookup(host_name, dict_to_modify):
    """
    uses socket to do a forward lookup on host
    Does not return anything, inserts values into forward_lookup_dict
    """
    try:
        host_ip = socket.gethostbyname(host_name)
        DictionaryHandling.add_to_dictionary(forward_lookup_dict, host_name, "IP Address", host_ip)
    except socket.gaierror:
        try:
            socket.inet_aton(host_name)
            print("You should be using FQDN instead of IPs in your ansible host file!")
            pass
        except socket.error:
            pass
        DictionaryHandling.add_to_dictionary(dict_to_modify, host_name, "IP Address", None)


def check_reverse_dns_lookup(lookup_dict, dict_to_modify):
    """
    uses socket to do a reverse lookup on hosts in forward_lookup_dict
    Does not return anything, inserts values into reverse_lookup_dict
    """
    for server_name in lookup_dict.keys():
        host_ip = lookup_dict[server_name]["IP Address"]
        if host_ip is not None:
            try:
                hostname = socket.gethostbyaddr(host_ip)
                DictionaryHandling.add_to_dictionary(dict_to_modify, server_name, "PTR Record", hostname[0])
            except socket.herror:
                DictionaryHandling.add_to_dictionary(dict_to_modify, server_name, "PTR Record", None)
        else:
            DictionaryHandling.add_to_dictionary(dict_to_modify, server_name, "PTR Record", None)


def check_docker_files(host, ssh_obj, files_modified_dict, dict_to_compare, remote_sha_sum_dict):
    """
    check_docker_files assumes there is already a paramiko connection made to the server in question
    It attempts to take a sha256sum of the files in file_list
    """
    for files in dict_to_compare.keys():
        try:
            temp_list = HandleSSHConnections.run_remote_commands(ssh_obj, "sha256sum %s" % files)
            shortened_file_name = files.split("/")[-1]
            for line in temp_list:
                sha_sum = line.split()[0]
                if line.strip().split()[0] == dict_to_compare[files]:
                    modified = False
                    DictionaryHandling.add_to_dictionary(files_modified_dict, host, "%s has been modified" %
                                                         shortened_file_name, modified)
                else:
                    modified = True
                    DictionaryHandling.add_to_dictionary(files_modified_dict, host, "%s has been modified" %
                                                         shortened_file_name, modified)
                # Added the file name and sha sum in the key to be able to associate the sum to modified flag
                # This will help to identify it for colourization
                DictionaryHandling.add_to_dictionary(remote_docker_file_sums_dict, host, "%s sha256sum : %s" %
                                                     (shortened_file_name, sha_sum), modified)
        except socket.error:
            print("No SSH connection is open")


def is_docker_running(server_name, output, dict_to_modify):
    """
    is_docker_running checks whether docker is active. Stores the results in docker_service_check_dict
    """
    docker_running = False
    if output is not None:
        for line in output:
            if "Active:" in line:
                if "inactive" in line:
                    docker_running = False
                elif "active" in line:
                    docker_running = True
                    active_since = line
    if docker_running:
        print("Docker is active")
        DictionaryHandling.add_to_dictionary(dict_to_modify, server_name, "Docker Running", True)
    else:
        print("Docker is not running: \n")
        for line in output:
            print(textColors.FAIL + line + textColors.ENDC),
        DictionaryHandling.add_to_dictionary(dict_to_modify, server_name, "Docker Running", "Warning")


def is_docker_enabled(server_name, output, dict_to_modify):
    """
    is_docker_enabled checks to see if docker is enabled in systemd.
    Stores the results in docker_service_check_dict
    """
    if output is not None:
        for line in output:
            if "Loaded: " in line:
                if "enabled" in line.split("vendor preset")[0]:
                    DictionaryHandling.add_to_dictionary(dict_to_modify, server_name, "Docker Enabled", True)
                else:
                    DictionaryHandling.add_to_dictionary(dict_to_modify, server_name, "Docker Enabled", "Warning")


def is_host_subscribed(server_name, dict_to_modify, subscript_status):
    """
    is_host_subscribed uses subprocess to run the subscription-manager command.
    It parses the output for the word 'Current' if found, returns true, otherwise returns false

    """
    for line in subscript_status:
        if "Overall" in line:
            if "Current" in line:
                DictionaryHandling.add_to_dictionary(dict_to_modify, server_name, "Subscribed", True)
            else:
                DictionaryHandling.add_to_dictionary(dict_to_modify, server_name, "Subscribed", False)


def which_repos_are_enabled(server_name, dict_to_modify, repo_info, these_should_be_enabled):
    """
    which_repos_are_enabled parses the output from 'subscription-manager repos' command.
    After parsing, it stores enabled repos in a dictionary with the hostname as the key.
    This function does not return anything
    """
    repo_id_keyword = "Repo ID:"
    repo_enabled_keyword = "Enabled:"
    for line in repo_info:
        if repo_id_keyword in line:
            repo_name = line.split(repo_id_keyword)[1].strip()
        if repo_enabled_keyword in line:
            if "1" in line.split(repo_enabled_keyword)[1]:
                enabled = True
            else:
                enabled = False
            if repo_name in these_should_be_enabled:
                DictionaryHandling.add_to_dictionary(dict_to_modify, server_name, repo_name, enabled)


def installed_package_query(server_name, repo_dict_to_modify, package_list, ssh_obj):
    """
    installed_package_query uses the yum to determine if packages exist on the remote system
    Does not return anything, instead uses DictionaryHandling.add_to_dictionary to populate dictionaries
    for processing later in the summation
    """
    ose_required_packages_installed = []
    ose_required_packages_not_installed = []
    temp_list = HandleSSHConnections.run_remote_commands(ssh_obj, "yum list installed")
    installed_on_system = []
    for package in temp_list:
        package_name = package.split(".")[0]
        installed_on_system.append(package_name)
    for package in package_list:
        if package in installed_on_system:
            ose_required_packages_installed.append(package)
        else:
            ose_required_packages_not_installed.append(package)
    if len(package_list) != len(ose_required_packages_installed):
        DictionaryHandling.add_to_dictionary(repo_dict_to_modify, server_name, "Missing",
                                             ose_required_packages_not_installed)
    else:
        DictionaryHandling.add_to_dictionary(repo_dict_to_modify, server_name, "All OSE Packages Installed", True)


def update_required_query(server_name, package_update_dict, package_list, ssh_obj):
    """
    update_required_query uses the yum to determine if packages have updates available
    Does not return anything, instead uses DictionaryHandling.add_to_dictionary to populate dictionaries
    for processing later in the summation
    """
    packages_to_be_updated = HandleSSHConnections.run_remote_commands(ssh_obj, "yum list updates")
    ose_package_needs_update = False
    system_up_to_date = True
    if len(packages_to_be_updated) > 2:
        system_up_to_date = False
        for package in packages_to_be_updated:
            package_name = package.split(".")[0]
            if package_name in package_list:
                ose_package_needs_update = True
                DictionaryHandling.add_to_dictionary(package_update_dict, server_name, "Update available for",
                                             package_name)
    if not ose_package_needs_update:
         DictionaryHandling.add_to_dictionary(package_update_dict, server_name, "System is up to date",
                                              system_up_to_date)

if __name__ == "__main__":
    if options.ansible_host_file is None:
        print("No Ansible host file provided. This is required")
        parser.print_help()
        sys.exit()

    if options.show_sha_sums is None:
        show_sha_sums = False
    elif "y" in options.show_sha_sums.lower()[0]:
        show_sha_sums = True
    elif "n" in options.show_sha_sums.lower()[0]:
        show_sha_sums = False
    else:
        print("Plesse enter yes/no or y/n to display/hide sha sums")
        parser.print_help()
        sys.exit()

    ansible_host_list = process_host_file(options.ansible_host_file)
    for server in ansible_host_list:
        can_connect_to_server = test_ssh_keys(server, ansible_ssh_user)
        # if we can connect to remote host, go ahead and run the verification checks
        if can_connect_to_server:
            ssh_connection.open_ssh(server, ansible_ssh_user)
            check_docker_files(server, ssh_connection, docker_files_have_been_modified_dict,
                               original_docker_file_hashes, remote_docker_file_sums_dict)
            installed_package_query(server, repo_dict, ose_required_packages_list, ssh_connection)
            update_required_query(server, package_updates_available_dict, ose_required_packages_list, ssh_connection)
            is_selinux_enabled(server, ssh_connection, selinux_dict)
            systemctl_output = HandleSSHConnections.run_remote_commands(ssh_connection, "systemctl status docker")
            is_docker_enabled(server, systemctl_output, docker_service_check_dict)
            is_docker_running(server, systemctl_output, docker_service_check_dict)
            sub_status = HandleSSHConnections.run_remote_commands(ssh_connection, "subscription-manager status")
            is_host_subscribed(server, subscription_dict, sub_status)
            repo_information = HandleSSHConnections.run_remote_commands(ssh_connection, "subscription-manager repos")
            which_repos_are_enabled(server, repo_dict, repo_information, ose_repos)
            ssh_connection.close_ssh()
        check_forward_dns_lookup(server, forward_lookup_dict)
        check_reverse_dns_lookup(forward_lookup_dict, reverse_lookup_dict)

    ##### Format output and display summary
    print(textColors.HEADER + textColors.BOLD + "\n\nSELinux Checks" + textColors.ENDC)
    DictionaryHandling.format_dictionary_output(selinux_dict)

    print(textColors.HEADER + textColors.BOLD + "\n\nDocker Section (sha256sum below)" + textColors.ENDC)
    if show_sha_sums:
        DictionaryHandling.format_dictionary_output(docker_files_have_been_modified_dict, remote_docker_file_sums_dict,
                                                docker_service_check_dict)
    else:
        DictionaryHandling.format_dictionary_output(docker_files_have_been_modified_dict, docker_service_check_dict)

    print(textColors.HEADER + textColors.BOLD + "\n\nDNS Lookups" + textColors.ENDC)
    DictionaryHandling.format_dictionary_output(forward_lookup_dict, reverse_lookup_dict)

    print(textColors.HEADER + textColors.BOLD + "\n\nPackages and repo information" + textColors.ENDC)
    DictionaryHandling.format_dictionary_output(repo_dict, subscription_dict, ose_package_not_installed_dict,
                                                ose_package_installed_dict, package_updates_available_dict)
