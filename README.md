# ose-utils | OpenShift Enterprise 3

Miscellaneous utilities for use with OpenShift Enterprise

Note that these utilities must be run from a shell command line on a broker, and use the OpenShift Ruby on Rails infrastructure.

All of the warnings about over-using broker utilities also apply to these utilities so include lots of "sleeps" if scripting.

All of the ruby scripts support a --help option that produces slightly useful output.

Note that these scripts all use unpublished internal API's that may be changed with no warning.

If you want write access to this repository, ping me at my Red Hat address.

No warranty is offered or implied and use of these scripts may destroy your entire OpenShift environment.

 - osc-cleanup-project : Utility script for deleting all resources in a project. Project is selected based current-context on kubeconfig login.

 - dns.sh : Wrapper around nsupdate for adding/removing CNAME records to our split-dns. 
