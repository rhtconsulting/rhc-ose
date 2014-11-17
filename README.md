ose-utils
=========
Miscellaneous utilities for use with OpenShift Enterprise

Note that these utilities must be run from a shell command line on a broker, and use
the OpenShift Ruby on Rails infrastructure.

All of the warnings about over-using broker utilities also apply to these utilities
so include lots of "sleeps" if scripting.

All of the ruby scripts support a --help option that produces slightly useful output.

Note that these scripts all use unpublished internal API's that may be changed with no
warning.

If you want write access to this repository, ping me at my Red Hat address.

No warranty is offered or implied and use of these scripts may destroy your entire
OpenShift environment.

- oo-auth-token
Generates an authentication token for an OpenShift login.
Login must already exist.
Primarily for use with the rhc command for back-end scripting, but can also be used with
service accounts.

- oo-delete-user.sh
Bash script to inefficiently remove an OpenShift login.

- oo-list
Lists broker data in a form compatible with traditional shell utilities like grep and sed.
Intended to quickly answer questions of the form "How may applications are in OpenShift?"
Implementation is not particularly efficient, and this script will probably explode in a
large environment, such as Online. Use --help to see what's available.

- oo-purge-apps
Utility to purge applications more than X days old.
Intended for use in a sandbox type environment where applications are only intended to have
a short life span.
Note that there are also option to generate warnings, and to stop applications without
destroying them. These are intended as signals that an application will be purged shortly.
