ose3 Solutions
=============

Solutions for common use cases during the installation and operation of OpenShift Enterprise 3

## Disconnected Installations

Coming soon

## Infrastructure Services Certificates

These set of solutions are centered around the integration of certificates for core OpenShift infrastructure services, such as logging and metrics

* Applying the default platform CA certificate to logging and metrics components

The logging and metrics components of OpenShift each utilize their own certificate authority to generate certificates for each component. This can be troublesome as it is yet another set of certificates to manage with the platform. 

The `certificates-secrets-metrics-logging.sh` script is available to generate certificates based on the OpenShift platform CA. The certificates and then stored in a secret for the deployer of each component to utilize.

To run the script, two parameters are required:

* Component to target (metrics or logging)
* Public hostname to associate with the certificate

```
 ./certificates-secrets-metrics-logging.sh -t=logging -h=kibana.apps.openshift.example.com
```

## PKI Integration

Coming soon