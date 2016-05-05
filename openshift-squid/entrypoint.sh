#!/bin/bash --

if [ -n "$SQUID_CONF" ] ; then
	echo "$SQUID_CONF" > /etc/squid/squid.conf
else
	#
	# Local domains is a space separated list of domains that do not require/use
	# external proxy.
	# It can either represent whole domains (e.g. .example.com) note leading
	# period or individual hostnames e.g. www.example.com
	#
	if [ -n "$LOCAL_DOMAINS" ] ; then
		for DOM in $LOCAL_DOMAINS ; do
			echo acl direct-connect dstdomain $DOM >> /etc/squid/squid.conf
		done
		echo "always_direct allow direct-connect" >> /etc/squid/squid.conf
	fi
	for IP in $(env | sed -n -e '/SERVICE_HOST/s/^[^=]*=//p') ; do
		echo acl service-connect dstdomain $IP >> /etc/squid/squid.conf
	done
	echo "always_direct allow service-connect" >> /etc/squid/squid.conf

	[ -n "$SQUID_XTRA_CONF" ] && echo "$SQUID_XTRA_CONF" >> /etc/squid/squid.conf

	echo "never_direct allow all" >> /etc/squid/squid.conf
	if [ -n "$UPSTREAM_PROXY" ] ; then
		[ -n "$UPSTREAM_LOGIN" ] && tmp="login=$UPSTREAM_LOGIN"
		echo "cache_peer ${UPSTREAM_PROXY} parent 3128 0 no-query no-digest $tmp" >> /etc/squid/squid.conf
	fi
fi

echo "Starting squid..."
exec /usr/sbin/squid -f /etc/squid/squid.conf -NCd 1 ${SQUID_ARGS}
