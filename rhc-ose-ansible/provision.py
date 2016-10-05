#!/usr/bin/python

import os
import sys
from library.helpers import error_out
import subprocess
import glob
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--inventory', '-i', action='store', dest='inventory_file', help='Path to an ansible inventory file '
                                                                                     '(defaults to /etc/ansible/hosts)')
parser.add_argument('--installer-path', '-p', action="store", dest='installer_path',
                    help='Path to the openshift-ansible directory')
parser.add_argument('--extra-vars', '-e',  action='append', dest='extra_vars', nargs='+',
                    help='Additional vars to pass to Ansible')
options = parser.parse_args()

script_base_dir = os.path.realpath(os.path.dirname(sys.argv[0]))


def provision(ansible_opts, script_dir, path_to_installer='/usr/share/ansible/openshift-ansible'):
    ansible_provision_command = "ansible-playbook %s %s/ose-provision.yml" % ( ansible_opts, script_dir)
    # Run the command and check the exit status
    provision_exit_status = subprocess.Popen([ansible_provision_command], stderr=subprocess.STDOUT,
                                             stdout=subprocess.PIPE).communicate().returncode
    # if the exit status is anything other than 0, assume a failure, call the error_out function and bail
    if provision_exit_status != 0:
        error_out("Provisioning run failed: %s" % ansible_provision_command, provision_exit_status)
    search_inventory_file_name = '%s/inventory_*' % script_dir
    try:
        openshift_inventory = max(glob.iglob(search_inventory_file_name), key=os.path.getctime)
    except ValueError:
        error_out(("No inventory file can be found at %s" % search_inventory_file_name))
    
    # In theory it script should have bailed at this point without either the inventory or installer path
    ansible_install_command = "ansible-playbook -i %s %s/playbooks/byo/config.yml" % (openshift_inventory,
                                                                                      path_to_installer)

    installation_exit_status = subprocess.Popen([ansible_install_command], stderr=subprocess.STDOUT,
                                                stdout=subprocess.PIPE).communicate().returncode

    if installation_exit_status != 0:
        error_out("Openshift installer failed to run with %s" % ansible_install_command, installation_exit_status)
        
    post_install_command = "ansible-playbook -i %s %s/playbooks/openshift/post-install.yaml" % ( openshift_inventory,
                                                                                                 script_dir)
    post_install_exit_status = subprocess.Popen([post_install_command], stderr=subprocess.STDOUT,
                                                stdout=subprocess.PIPE).communicate().returncode
    if post_install_exit_status != 0:
        error_out("Post install failed to run with: %s" % post_install_command)


if options.extra_vars is not None:
    ansible_opts = "-i %s -e rhc_ose_inv_dest=%s " % (options.inventory_file, script_base_dir)
    for option in options.extra_vars:
        ansible_opts += ' -e %s' % option[0]
else:
    ansible_opts = "-e rhc_ose_inv_dest=%s " % script_base_dir

if options.installer_path is not None:
    provision(ansible_opts, script_base_dir, options.installer_path)
else:
    provision(ansible_opts, script_base_dir)
