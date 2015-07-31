# Ticket-Monster OpenShift V3 Demo

This folder contains the resources necessary to run the Ticket-Monster demonstration application on OpenShfit V3

## What is Ticket-Monster?

The Ticket-Monster is a moderately complex application that demonstrates how to build modern applications using JBoss web technologies. It is used to illustrate how to utilize JBoss Applications within the OpenShift V3 environment.

## Build and deployment Options

OpenShift provides three options for building applications:

1. Docker Build
2. Source to image (S2I)
3. Custom Image Builder

Examples of retrieving a pre-packaged application from a remote source is demonstrated in this repository using a custom image builder and a source to image. While the overall outcome is the same, there are reasons for choosing each type of build.

## Source to Image (S2I Build)

A Source to Image (S2I) is a tool for building repeatable docker images.  It will take existing source code and produce a new layer that is built on top of an existing image. One of the benefits of a S2I is that is supports the concept of *incremental builds*, which will save a previous build on the image for use in subsequent builds. S2I features a configurable platform for defining the build steps and ultimate execution of an images. S2I scripts can be defined within a image or in source code. 

## Custom Builder 

A custom build is similar to a traditional docker build, with the exception of specifically controlling the functionality and execution of the build itself. By default, images are built using the generic OpenShift *docker-builder*. This option is desirable when it is desired to customize the process of building and deploying a Docker image.


## Installing the Configurations

This folder contains the following files necessary to prepare OpenShift to run the demo. 

* *jboss-eap-packaged-builder-imagestream.json* - ImageStream for for the custom image builder
* *ticket-monster-app-custom-template.json* - Used to produce the objects in OpenShift necessary to run the demo built using a custom builder
* *ticket-monster-app-s2i-template.json* - Used to produce the objects in OpenShift necessary to run the demo using S2I

### EAP Packaged Builder ImageStream (Custom Builder)

The EAP Packaged Builder is a custom image builder used to retrieve a previously packaged application (such as a war or ear) outside of OpenShift (and stored in an Enterprise Maven Repository [Such as Nexus]) onto an instance of JBoss Enterprise Application Platform. 

To add the ImageStream, run the following command on the OpenShift master as *root* or using a user with access to the *openshift* project:

    oc create -f jboss-eap-packaged-builder-imagestream.json -n openshift


## Running an Example

You can choose to leverage the custom builder or S2I build strategy. The following will describe both strategies for instantiating a template followed by building and deploying the application. The Ticket-Monster template will instantiate the objects necessary to run the Ticket-Monster application within OpenShift. Optional and required parameters are used to drive the configurations of the application

### Custom Builder Ticket-Monster Template (Custom Builder)

Execute the following command to add the template either on the OpenShift master as *root* or using an user with access to the *openshift* project:  

    oc create -f ticket-monster-app-template.json -n openshift


## Creating an Application from the Ticket Monster Custom Builder Template

The Custom Builder Ticket Monster template contains a set of parameters that are used to configure the application. These parameters not only provide configurations for the application itself, but the source location of the remote packaged archive.  

The following table describes the parameters in the template

| Name | Description | Default Value|
|----------|----------------|--------------------|
|APPLICATION_NAME| The name for the application| |
|APPLICATION_HOSTNAME|Custom hostname for service routes.  Leave blank for default hostname, e.g.: <application-name>.<project>.<default-domain-suffix>| |
|SRC_APP_URL|Location of the prepackaged application| |
|SRC_APP_NAME|Final name of the deployed application|ROOT.war |
|UPSTREAM_IMAGE|Image used to run the application|registry.access.redhat.com/jboss-eap-6/eap-openshift|
|UPSTREAM_IMAGE_TAG|Tag of the image used to run the application|latest|
|HORNETQ_QUEUES|Queue names| |
|HORNETQ_TOPICS|Topic names| |
|HORNETQ_CLUSTER_PASSWORD|HornetQ cluster admin password|Generated expression|

The following command can be used to create a new application from the template:

    oc new-app eap6-custom-packaged --param=APPLICATION_NAME=tm,APPLICATION_HOSTNAME=tm.ose.example.com,SRC_APP_URL="http://example.com/nexus/com/example/sample-app/1.0.0/sample-app-1.0.0.war"
    

## Creating an Application from the Ticket Monster Custom Builder Template

The S2I Ticket Monster template contains a set of parameters that are used to configure the application. These parameters not only provide configurations for the application itself, but the source location of the remote packaged archive.  

The following table describes the parameters in the template

| Name | Description | Default Value|
|----------|----------------|--------------------|
|APPLICATION_NAME| The name for the application| |
|APPLICATION_HOSTNAME|Custom hostname for service routes.  Leave blank for default hostname, e.g.: <application-name>.<project>.<default-domain-suffix>| |
|SRC_APP_URL|Location of the prepackaged application| |
|SRC_APP_NAME|Final name of the deployed application|ROOT.war |
|UPSTREAM_IMAGE|Image used to run the application|jboss-eap6-openshift|
|UPSTREAM_IMAGE_TAG|Tag of the image used to run the application|latest|
|GIT_URI|Git source URI for S2I application scripts|https://github.com/sabre1041/jboss-eap-packaged-builder|
|GIT_REF|Git branch/tag reference for the S2I application scripts|3.0|
|HORNETQ_QUEUES|Queue names| |
|HORNETQ_TOPICS|Topic names| |
|HORNETQ_CLUSTER_PASSWORD|HornetQ cluster admin password|Generated expression|

The following command can be used to create a new application from the template:

    oc new-app eap6-s2i-packaged --param=APPLICATION_NAME=tm,APPLICATION_HOSTNAME=tm.ose.example.com,SRC_APP_URL="http://example.com/nexus/com/example/sample-app/1.0.0/sample-app-1.0.0.war"
    

## Build the application

Once the objects from the template have been created (irregardless of the type of builder used), start a build of the application:

    oc start-build tm

The template has been configured to deploy the newly created image as soon as it has been built. If the new application example from the previous section was used, the application will be available at [http://tm.ose.example.com](http://tm.ose.example.com)

## Resources

* Builds
	* [Origin Builds](https://github.com/openshift/origin/blob/master/docs/builds.md)
	* [OSE Builds](https://docs.openshift.com/enterprise/3.0/dev_guide/builds.html)