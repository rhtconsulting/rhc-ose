#Enhance CICD Demo to Add the "OPS" side of the story 

##Overview
The goal of this adoc / presentation was to do the following: demonstrate OPS Role in the Software Delivery Process.
Our CI/CD Pipeline demo tells the story from the Developers' point of view. However, Ops teams should also play a part in the software delivery process.
This demo aims to enhance the CI/CD Demo materials we have to show how Dev code and Ops code are merged in the build pipeline.


## Demo Requirements

The following components are required:
1. OSE V3.1 Install (See configuration details below)
2. Jenkins server or other artifact repository to hold binary assembly (war)
3. Git Server (GitHub, or GitLab)

### OSE Configuration
For this demo a simple (non H/A) OSE environment would be sufficient.

### Demo Commands
The complete demo script is available in the .adoc file.

### Git Repos used in demo
Two Git repositories were create to display both the OPS and Development sides of the story.  Those repositories along with the Ticket Monster application are described below.
1. Ticket Monster
Reference JBOSS web application reference architecture
Used to create a war artifact that will be used as the Jenkins artifact
https://github.com/jboss-developer/ticket-monster

2. Ops Git Repo
Git repo that holds configuration information (Infrastructure as Code) used to generate (in our case) a custom EAP6 image
https://github.com/themoosman/ops-custom-eap6

3. Ticket Monster s2i Image Build
Git repo that hold the scripts (s2i) used to consume development artifacts (war) and create a docker image. Said image is uploaded to a master image repository where it’s pushed to dev, qa, prod, etc.
https://github.com/themoosman/ticket-monster-ose-s2i-build


## Presenter Information
Any presenter should have:
1. Working knowledge on how OSE works
2. Extensive knowledge around how OPS works (both current day and historical)
3. How CI/CD works within an OSE environment
