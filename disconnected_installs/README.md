# Scripts for Executing Disconnected Installs

1. Install a registry server

```
yum install -y docker-registry

firewall-cmd --add-port 5000/tcp --permanent
firewall-cmd --reload

systemctl start docker-registry.service
systemctl enable docker-registry.service

```

2. Run the `docker-registry-sync` script to sync Red Hat images to private registry

```
./docker-registry-sync --from=registry.access.redhat.com --local=<registry-server-ip>:5000 --file=./openshift_images-3.2.0.20
```
