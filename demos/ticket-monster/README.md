# Ticket-Monster OpenShift V3 Demo

This folder contains the resources necessary to run the Ticket-Monster demonstration application on OpenShfit V3

## What is Ticket-Monster?

The Ticket-Monster is a moderately complex application that demonstrates how to build modern applications using JBoss web technologies. It is used to illustrate how to utilize JBoss Applications within the OpenShift V3 environment.

## Installing the Configurations

This folder contains the following files necessary to prepare OpenShift to run the demo. 

* *jboss-eap-packaged-builder-imagestream.json* - ImageStream for for the custom image builder
* *ticket-monster-app-template.json* - Used to produce the objects in OpenShift necessary to run the demo


### EAP Packaged Builder ImageStream

The EAP Packaged Builder is a custom image builder used to retrieve a previously packaged application (such as a war or ear) outside of OpenShift (and stored in an Enterprise Maven Repository [Such as Nexus]) onto an instance of JBoss Enterprise Application Platform. 

To add the ImageStream, run the following command on the OpenShift master as *root* or using a user with access to the *openshift* project:

    oc create -f jboss-eap-packaged-builder-imagestream.json -n openshift

### Ticket-Monster Template

The Ticket-Monster template will instantiate the objects necessary to run the Ticket-Monster application within OpenShift. Optional and required parameters are used to drive the configurations of the application,

Execute the following command to add the template either on the OpenShift master as *root* or using an user with access to the *openshift* project:  

    oc create -f jticket-monster-app-template.json -n openshift


## Creating an Application from the Ticket Monster Template

The Ticket Monster template contains a set of parameters that are used to configure the application. These parameters not only provide configurations for the application itself, but the parameters to retrieve the prepackaged source from a remote Nexus Artifact repository.  

The following table describes the parameters in the template

| Name | Description | Default Value|
|----------|----------------|--------------------|
|APPLICATION_NAME| The name for the application| |
|APPLICATION_HOSTNAME|Custom hostname for service routes.  Leave blank for default hostname, e.g.: <application-name>.<project>.<default-domain-suffix>| |
|ARTIFACT_REMOTE_HOST| Remote host containing the packaged artifact (hostname and port [if not 80])| |
|ARTIFACT_GROUP_ID|Maven group ID of the packaged artifact| |
|ARTIFACT_ID|Maven artifact ID of the packaged artifact| |
|ARTIFACT_VERSION|Maven version of the packaged artifact| |
|ARTIFACT_PACKAGING|Maven packaging type of the packaged artifact|war|
|UPSTREAM_IMAGE|Image used to run the application|registry.access.redhat.com/jboss-eap-6/eap-openshift|
|UPSTREAM_IMAGE_TAG|Tag of the image used to run the application|latest|
|HORNETQ_QUEUES|Queue names| |
|HORNETQ_TOPICS|Topic names| |
|HORNETQ_CLUSTER_PASSWORD|HornetQ cluster admin password|Generated expression|

The following command can be used to create a new application from the template:

    oc new-app --template=eap6-packaged --param=APPLICATION_NAME=tm,APPLICATION_HOSTNAME=tm.ose.example.com,ARTIFACT_REMOTE_HOST=cicd.ose.example.com:8081,ARTIFACT_GROUP_ID=org.jboss.examples,ARTIFACT_ID=ticket-monster,ARTIFACT_VERSION=2.7.0-SNAPSHOT
    
## Build the application

Once the objects from the template have been created, start a build of the application:

    oc start-build tm

The template has been configured to deploy the newly created image as soon as it has been built. If the new application example from the previous section was used, the application will be available at [http://tm.ose.example.com/ticket-monster-2.7.0-SNAPSHOT](http://tm.ose.example.com/ticket-monster-2.7.0-SNAPSHOT)

## Resources

* [Builds](https://github.com/openshift/origin/blob/master/docs/builds.md)