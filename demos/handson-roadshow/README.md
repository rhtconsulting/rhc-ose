# OpenShift Hands On Roadshow

The OpenShift hands on roadshow provides attendees the ability to ramp up on the OpenShift ecosystem through a series of interactive exercises. This folder contains the necessary instructions on how to prepare an environment to complete exercises

## Exercises

The exercises for the roadshow is found at the following location which contains the necessary tooling and materials

[https://github.com/sabre1041/openshift-internal-roadshow](https://github.com/sabre1041/openshift-internal-roadshow)

## OpenShift Prerequisites

The roadshow requires an OpenShift environment be created beforehand to act as an execution environment for the exercises. As with all OpenShift deployments, adequate compute power, storage and network connectivity must be in place prior to provisioning.

Provisioning the environment can be completed manually or by utilizing any of the provisioning script found in this repository. 

Access to the machine acting as the OpenShift master is required to run the prerequisite provisioning scripts described below

## Provisioning Scripts

A provisioning script is available to perform the steps necessary to prepare an OpenShift environment to execute the exercises.

* [setup_internal_roadshow_env.sh](setup_internal_roadshow_env.sh)

This script performs the following actions by default:

* Utilizing the [HTPasswd](https://docs.openshift.com/enterprise/3.1/install_config/configuring_authentication.html#HTPasswdPasswordIdentityProvider) identity provider, creates X number of users that can be used to access the environment
* Configures a non-persistent [aggregated logging](https://docs.openshift.com/enterprise/3.1/install_config/aggregate_logging.html) infrastructure with a separate ops cluster
* Configures [cluster metrics](https://docs.openshift.com/enterprise/3.1/install_config/cluster_metrics.html)
* Creates a new [group](https://docs.openshift.com/enterprise/3.0/architecture/additional_concepts/authentication.html#users-and-groups) containing the users created earlier
* Creates an example project that can be used to demonstrate core concepts in OpenShift
	* Adds the view role to the group created earlier
	* Deploys a simple [application](https://github.com/gshipley/smoke)
	* Scales the application with a replica count of 2


## Executing the Provisioning Script

The provisioning script accepts parameters to customize the behavior of the environment. By default, the script can be executed without any customizations assuming the following environment constraints are in place:

* Wildcard subdomain for applications is *apps.example.com*

## Validating the Environment

The following methods can be used to validate the successful execution of the roadshow provisioning script

1. Attempt to login to the environment at [https://master.ose.example.com](https://master.ose.example.com) with the username/password credential combination of `user01/redhat`
2. A project `OpenShift Roadshow Demo` should be visible by default to all roadshow users
3. Validate the logging infrastructure is in place by navigating to [https://kibana.apps.ose.example.com](https://kibana.apps.ose.example.com)
4. Validate the logging infrastructure is in place
	1. Navigate to [https://hawkular-metrics.apps.ose.example.com/hawkular/metrics](https://hawkular-metrics.apps.ose.example.com/hawkular/metrics) and validate the metrics service is *STARTED*
	2. Login to the OpenShift console and browse to the *OpenShift Roadshow Demo* project. Hover over the **Browse** tab on the lefthand side and select one of the *Running* pods. Select the **Metrics** tab and validate metrics resources are being returned

## Alternative Configurations

* LDAP Authentication
	* Create X number of users
	* Create a group that includes the users created above
	* When running the execution script, add the `--group` parameter to match the value created in LDAP
	* Replace the *HTPasswd* identity provider with [LDAP Authorization](https://docs.openshift.com/enterprise/3.1/install_config/configuring_authentication.html#LDAPPasswordIdentityProvider)

