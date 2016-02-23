This is a squid proxy configured to run inside OpenShift.

Request routing is as follows:
- Services in default and openshift projects are routed directly
- Services in other projects are blocked
- Services hosted on local RFC1918 addresses will be routed directly
- Domains defined in environment variables "LOCALDOMAINS" will be routed directly
- All other requests will be routed to proxy defined by environment variable "UPSTREAM_PROXY"

- If credentials are required for UPSTREAM_PROXY, they can be defined in "UPSTREAM_LOGIN" in
the form username:password
example: UPSTREAM_LOGIN=proxyuser:passw0rd

Only requests to ports 80, 443, 1936, 5000 and 8443 are permitted.

The config file assumes the default IP address ranges for pod and service IP addresses.

A complete replacement squid.conf can be defined in the environment variable "SQUID_CONF"

Sample deploymentConfig and service definitions are provided.

/etc/sysconfig/docker needs the following lines added, to force use of proxy:
```
http_proxy=http://squid.default.svc.cluster.local:3128
https_proxy=http://squid.default.svc.cluster.local:3128
# This is the IP address for the registry
no_proxy=172.30.48.143:5000,172.30.0.1,kubernetes.default.svc.cluster.local,docker-registry.default.svc.cluster.local:5000
```
The assumption is that the squid proxy image is uploaded to the OpenShift registry.
It will not start if it has to be pulled from an external registry.

BUILDCONFIGS

The proxy needs to be defined both in the source section (for the initial Git pull)
and in the strategy section to be used for pulling other artifacts.
```
Sample:
  source:
    git:
      httpProxy: http://squid.default.svc.cluster.local:3128
      httpsProxy: http://squid.default.svc.cluster.local:3128
      uri: https://github.com/openshift/nodejs-ex.git
    type: Git
  strategy:
    sourceStrategy:
      env:
      - name: http_proxy
        value: http://squid.default.svc.cluster.local:3128
      - name: https_proxy
        value: http://squid.default.svc.cluster.local:3128
```
INITIAL SETUP

Note this proxy will not be available during the initial OpenShift install, so the following lines should be added 
to /etc/sysconfig/docker:
```
http_proxy=http://proxy.corp.example.com:8080
https_proxy=http://proxy.corp.example.com:8080
# This is the IP address for the registry
no_proxy=172.30.48.143:5000,172.30.0.1,kubernetes.default.svc.cluster.local,docker-registry.default.svc.cluster.local:5000
```
Replace proxy.corp.example.com:8080 with the actual corporate proxy. If the coroporate proxy requires credentials, the following may work during initial setup:
```
http_proxy=http://username:password@proxy.corp.example.com:8080
https_proxy=http://username:password@proxy.corp.example.com:8080
# This is the IP address for the registry
no_proxy=172.30.48.143:5000,172.30.0.1,kubernetes.default.svc.cluster.local,docker-registry.default.svc.cluster.local:5000
```
