#!/bin/bash
AUTHORIZED_KEYS_FILE='https://raw.githubusercontent.com/redhat-consulting/ose-utils/openshift-enterprise-3/ose3eval/ose3_public_keys'

# Usage: added_lines oldfile newfile
added_lines() {
  diff --changed-group-format='%>' --unchanged-group-format='' --ignore-all-space $1 $2
}

pushd ~ > /dev/null
  curl -o public_keys.tmp -sS ${AUTHORIZED_KEYS_FILE}
  echo "$(added_lines .ssh/authorized_keys public_keys.tmp)" >> .ssh/authorized_keys
  rm public_keys.tmp
popd
