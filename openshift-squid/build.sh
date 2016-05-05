#!/bin/bash --

REGISTRY=registry.cloudapps.example.com

docker build -t $REGISTRY/openshift/squid:latest .
docker push $REGISTRY/openshift/squid:latest
