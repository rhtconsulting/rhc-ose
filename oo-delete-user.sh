#!/bin/bash --

for OO_USER in $@ ; do
	USER_NS=$(oo-admin-ctl-domain -l $OO_USER | grep Namespace: | cut -d' ' -f2 | sort -u)
	[ -n "$USER_NS" ] || continue

	echo Deleting account: $OO_USER
	sleep 1

	USER_APPS=$(oo-admin-ctl-domain -l $OO_USER | grep canonical_name: | cut -d' ' -f2)

	for APP in $USER_APPS; do
		echo oo-admin-ctl-app -l $OO_USER -a $APP -c destroy
		yes | oo-admin-ctl-app -l $OO_USER -a $APP -c destroy
		sleep 1
	done
	for NS in $USER_NS; do
		echo oo-admin-ctl-domain  -c delete -l $OO_USER -n $NS
		oo-admin-ctl-domain  -c delete -l $OO_USER -n $NS
		sleep 1
	done
	echo oo-admin-ctl-domain  -c delete -l $OO_USER
	oo-admin-ctl-domain  -c delete -l $OO_USER
	echo
done
