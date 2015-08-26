# OSE v3 API Toolset

## Instructions

This guide will help to get quickly working with the openshift API from a linux console. It provides some initial setup bash variables and functions so that you can run simple rest verbs from the command line (i.e. GET /some/path).

1. Log in to OpenShift using the CLI ( 'oc login --server=<master ip>')
2. Copy paste the 'Setup Script' into the command line, making sure to set the SERVER variable to the IP address of your master.
3. Once the Setup script is run in your terminal session, you should be able to copy/paste from the Sample API Requests below to get started making API requests.

## Setup Script
```bash
TOKEN=`oc whoami -t`
SERVER=master.d1.rhc-ose.labs.redhat.com # Master IP
AUTH="Authorization: Bearer $TOKEN"
CONTENT_TYPE="Content-Type: application/json"


POST() {
  echo "curl -kI -H \"$AUTH\" -H \"$CONTENT_TYPE\" -X POST --data-binary \"${DATA}\" https://${SERVER}:8443$1"
  curl -k -H "$AUTH" -H "$CONTENT_TYPE" -X POST --data-binary "${2}" https://${SERVER}:8443$1
}

GET() {
  echo "curl -kI -H \"$AUTH\" -H \"$CONTENT_TYPE\" -X GET https://${SERVER}:8443$1"
  curl -k -H "$AUTH" -H "$CONTENT_TYPE" -X GET https://${SERVER}:8443$1
}
```

## Sample API Calls

### Get Projects
```bash
GET /oapi/v1/projects
```

### Create Project
```bash
POST /oapi/v1/projectrequests '{
  "apiVersion": "v1beta3",
  "description": "Hello",
  "displayName": "My Project",
  "kind": "ProjectRequest",
  "metadata": {
    "name": "api-project"
  }
}'
```

### Create Service
```bash
POST /api/v1/namespaces/api-project/services '{
  "apiVersion": "v1",
  "kind": "Service",
  "metadata": {
    "annotations": {
      "description": "Exposes and load balances the application pods"
    },
    "labels": {
      "template": "nodejs-example"
    },
    "name": "nodejs-example"
  },
  "spec": {
    "ports": [
    {
      "name": "web",
      "port": 8080,
      "targetPort": 8080
    }
    ],
    "selector": {
      "name": "nodejs-example"
    }
  }
}'
```

### Create ImageStream
```bash
POST /oapi/v1/namespaces/api-project/imagestreams '{
  "apiVersion": "v1",
  "kind": "ImageStream",
  "metadata": {
    "annotations": {
      "description": "Keeps track of changes in the application image"
    },
    "labels": {
      "template": "nodejs-example"
    },
    "name": "nodejs-example"
  }
}'
```

### Create Buildconfig
```bash
POST /oapi/v1beta3/namespaces/api-project/buildconfigs '{
  "apiVersion": "v1",
  "kind": "BuildConfig",
  "metadata": {
    "annotations": {
      "description": "Defines how to build the application"
    },
    "labels": {
      "template": "nodejs-example"
    },
    "name": "nodejs-example"
  },
  "spec": {
    "output": {
      "to": {
        "kind": "ImageStreamTag",
        "name": "nodejs-example:latest"
      }
    },
    "source": {
      "contextDir": "",
      "git": {
        "ref": "",
        "uri": "https://github.com/openshift/nodejs-ex.git"
      },
      "type": "Git"
    },
    "strategy": {
      "sourceStrategy": {
        "from": {
          "kind": "ImageStreamTag",
          "name": "nodejs:0.10",
          "namespace": "openshift"
        }
      },
      "type": "Source"
    },
    "triggers": [
    {
      "type": "ImageChange"
    },
    {
      "github": {
        "secret": "QCQ1cRfqgysbQ7opST2HklJjJ1iYuwmqJ2bWPVQ5"
      },
      "type": "GitHub"
    }
    ]
  }
}'
```

### Create DeploymentConfig
```bash
POST /oapi/v1beta3/namespaces/api-project/deploymentconfigs '{
  "apiVersion": "v1",
  "kind": "DeploymentConfig",
  "metadata": {
    "annotations": {
      "description": "Defines how to deploy the application server"
    },
    "labels": {
      "template": "nodejs-example"
    },
    "name": "nodejs-example"
  },
  "spec": {
    "replicas": 1,
    "selector": {
      "name": "nodejs-example"
    },
    "strategy": {
      "type": "Rolling"
    },
    "template": {
      "metadata": {
        "labels": {
          "name": "nodejs-example"
        },
        "name": "nodejs-example"
      },
      "spec": {
        "containers": [
        {
          "env": [
          {
            "name": "DATABASE_SERVICE_NAME",
            "value": ""
          },
          {
            "name": "MONGODB_USER",
            "value": ""
          },
          {
            "name": "MONGODB_PASSWORD",
            "value": ""
          },
          {
            "name": "MONGODB_DATABASE",
            "value": ""
          },
          {
            "name": "MONGODB_ADMIN_PASSWORD",
            "value": ""
          }
          ],
          "image": "nodejs-example",
          "name": "nodejs-example",
          "ports": [
          {
            "containerPort": 8080
          }
          ]
        }
        ]
      }
    },
    "triggers": [
      {
        "imageChangeParams": {
          "automatic": true,
          "containerNames": [
            "nodejs-example"
          ],
          "from": {
            "kind": "ImageStreamTag",
            "name": "nodejs-example:latest"
          }
        },
        "type": "ImageChange"
      },
      {
        "type": "ConfigChange"
      }
    ]
  }
}'
```

### Create Route
```bash
POST /oapi/v1beta3/namespaces/api-project/routes '{
  "apiVersion": "v1",
  "kind": "Route",
  "metadata": {
    "labels": {
      "template": "nodejs-example"
    },
    "name": "nodejs-example"
  },
  "spec": {
    "host": "nodejs-example.openshiftapps.com",
    "to": {
      "kind": "Service",
      "name": "nodejs-example"
    }
  }
}'
```

### Get Pods
```bash
GET /api/v1/namespaces/api-project/pods
```

### Create Template
```bash
POST /oapi/v1/namespaces/api-project/processedtemplates '{
    "kind": "Template",
    "apiVersion": "v1",
    "metadata": {
        "name": "nodejs-example",
        "namespace": "api-project",
        "annotations": {
            "description": "An example Node.js application with no database",
            "iconClass": "icon-nodejs",
            "tags": "instant-app,nodejs"
        }
    },
    "objects": [
        {
            "kind": "Service",
            "apiVersion": "v1",
            "metadata": {
                "name": "nodejs-example",
                "annotations": {
                    "description": "Exposes and load balances the application pods"
                }
            },
            "spec": {
                "ports": [
                    {
                        "name": "web",
                        "port": 8080,
                        "targetPort": 8080
                    }
                ],
                "selector": {
                    "name": "nodejs-example"
                }
            }
        },
        {
            "kind": "Route",
            "apiVersion": "v1",
            "metadata": {
                "name": "nodejs-example"
            },
            "spec": {
                "host": "${APPLICATION_DOMAIN}",
                "to": {
                    "kind": "Service",
                    "name": "nodejs-example"
                }
            }
        },
        {
            "kind": "ImageStream",
            "apiVersion": "v1",
            "metadata": {
                "name": "nodejs-example",
                "annotations": {
                    "description": "Keeps track of changes in the application image"
                }
            }
        },
        {
            "kind": "BuildConfig",
            "apiVersion": "v1",
            "metadata": {
                "name": "nodejs-example",
                "annotations": {
                    "description": "Defines how to build the application"
                }
            },
            "spec": {
                "source": {
                    "type": "Git",
                    "git": {
                        "uri": "${SOURCE_REPOSITORY_URL}",
                        "ref": "${SOURCE_REPOSITORY_REF}"
                    },
                    "contextDir": "${CONTEXT_DIR}"
                },
                "strategy": {
                    "type": "Source",
                    "sourceStrategy": {
                        "from": {
                            "kind": "ImageStreamTag",
                            "namespace": "openshift",
                            "name": "nodejs:0.10"
                        }
                    }
                },
                "output": {
                    "to": {
                        "kind": "ImageStreamTag",
                        "name": "nodejs-example:latest"
                    }
                },
                "triggers": [
                    {
                        "type": "ImageChange"
                    },
                    {
                        "type": "GitHub",
                        "github": {
                            "secret": "${GITHUB_WEBHOOK_SECRET}"
                        }
                    }
                ]
            }
        },
        {
            "kind": "DeploymentConfig",
            "apiVersion": "v1",
            "metadata": {
                "name": "nodejs-example",
                "annotations": {
                    "description": "Defines how to deploy the application server"
                }
            },
            "spec": {
                "strategy": {
                    "type": "Rolling"
                },
                "triggers": [
                    {
                        "type": "ImageChange",
                        "imageChangeParams": {
                            "automatic": true,
                            "containerNames": [
                                "nodejs-example"
                            ],
                            "from": {
                                "kind": "ImageStreamTag",
                                "name": "nodejs-example:latest"
                            }
                        }
                    },
                    {
                        "type": "ConfigChange"
                    }
                ],
                "replicas": 1,
                "selector": {
                    "name": "nodejs-example"
                },
                "template": {
                    "metadata": {
                        "name": "nodejs-example",
                        "labels": {
                            "name": "nodejs-example"
                        }
                    },
                    "spec": {
                        "containers": [
                            {
                                "name": "nodejs-example",
                                "image": "nodejs-example",
                                "ports": [
                                    {
                                        "containerPort": 8080
                                    }
                                ],
                                "env": [
                                    {
                                        "name": "DATABASE_SERVICE_NAME",
                                        "value": "${DATABASE_SERVICE_NAME}"
                                    },
                                    {
                                        "name": "MONGODB_USER",
                                        "value": "${MONGODB_USER}"
                                    },
                                    {
                                        "name": "MONGODB_PASSWORD",
                                        "value": "${MONGODB_PASSWORD}"
                                    },
                                    {
                                        "name": "MONGODB_DATABASE",
                                        "value": "${MONGODB_DATABASE}"
                                    },
                                    {
                                        "name": "MONGODB_ADMIN_PASSWORD",
                                        "value": "${MONGODB_ADMIN_PASSWORD}"
                                    }
                                ]
                            }
                        ]
                    }
                }
            }
        }
    ],
    "parameters": [
        {
            "name": "SOURCE_REPOSITORY_URL",
            "description": "The URL of the repository with your application source code",
            "value": "https://github.com/openshift/nodejs-ex.git"
        },
        {
            "name": "SOURCE_REPOSITORY_REF",
            "description": "Set this to a branch name, tag or other ref of your repository if you are not using the default branch"
        },
        {
            "name": "CONTEXT_DIR",
            "description": "Set this to the relative path to your project if it is not in the root of your repository"
        },
        {
            "name": "APPLICATION_DOMAIN",
            "description": "The exposed hostname that will route to the Node.js service",
            "value": "nodejs-example.openshiftapps.com"
        },
        {
            "name": "GITHUB_WEBHOOK_SECRET",
            "description": "A secret string used to configure the GitHub webhook",
            "generate": "expression",
            "from": "[a-zA-Z0-9]{40}"
        },
        {
            "name": "DATABASE_SERVICE_NAME",
            "description": "Database service name"
        },
        {
            "name": "MONGODB_USER",
            "description": "Username for MongoDB user that will be used for accessing the database"
        },
        {
            "name": "MONGODB_PASSWORD",
            "description": "Password for the MongoDB user"
        },
        {
            "name": "MONGODB_DATABASE",
            "description": "Database name"
        },
        {
            "name": "MONGODB_ADMIN_PASSWORD",
            "description": "Password for the database admin user"
        }
    ],
    "labels": {
        "template": "nodejs-example"
    }
}'
```
