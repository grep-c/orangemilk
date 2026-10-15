# OrangeMilk (OMK)

OrangeMilk is an end-to-end DevOps lab project demonstrating how a source-code change can move through a CI/CD pipeline and become a running Kubernetes workload in AWS.

The project integrates:

- GitLab CI/CD
- Docker
- Amazon ECR Public
- Terraform
- Ansible
- AWS EC2
- k3s
- Helm
- Traefik

The application itself is intentionally simple. The focus of the project is the delivery pipeline and the interaction between the infrastructure, configuration-management, container, and Kubernetes tooling.

## Pipeline

```text
Git push
  ↓
Build Docker image
  ↓
Tag image with Git commit SHA
  ↓
Push image to Amazon ECR Public
  ↓
Terraform provisions AWS infrastructure
  ↓
Ansible bootstraps EC2
  ↓
Install and configure k3s + Helm
  ↓
Helm deploys the application
  ↓
Traefik exposes the application
  ↓
External smoke test
```

Each Docker image is tagged with the Git commit SHA that produced it. This makes a running deployment traceable back to a specific source revision.

## Architecture

```text
                       GitLab
                          |
                    GitLab Runner
                          |
        +-----------------+-----------------+
        |                 |                 |
        v                 v                 v
   Docker build       Terraform          Ansible
        |                 |                 |
        v                 v                 v
 ECR Public          AWS EC2          k3s + Helm
                                            |
                                            v
                                      Helm release
                                            |
                           +----------------+----------------+
                           |                |                |
                           v                v                v
                      Deployment         Service          Ingress
                           |                                |
                           v                                v
                         Pods                           Traefik
                                                            |
                                                            v
                                                     Public HTTP
```

The Kubernetes environment is a single-node k3s cluster running on an AWS EC2 instance.

## Repository structure

```text
.
├── app/
│   ├── Dockerfile
│   ├── src/
│   │   └── index.html
│   └── tests/
│       └── smoke.sh
│
├── config/
│   └── ansible/
│       └── playbooks/
│           ├── bootstrap.yml
│           ├── helm.yml
│           └── k3s.yml
│
├── deploy/
│   └── helm/
│       └── omk-webapp/
│           ├── Chart.yaml
│           ├── values.yaml
│           └── templates/
│               ├── deployment.yaml
│               ├── ingress.yaml
│               └── service.yaml
│
├── infra/
│   └── terraform/
│       ├── envs/
│       │   └── lab/
│       └── modules/
│           └── ec2_k3s_node/
│
├── docs/
├── .gitignore
├── .gitlab-ci.yml
└── README.md
```

## CI/CD stages

The GitLab pipeline contains the following stages:

```text
build
terraform
bootstrap
deploy
verify
destroy
```

### Build

The application image is built from `app/`.

The image is tagged using:

```text
CI_COMMIT_SHORT_SHA
```

and pushed to Amazon ECR Public.

The resulting image repository and tag are passed to later jobs using a GitLab dotenv artifact.

### Terraform

Terraform:

- validates the configuration
- creates an execution plan
- provisions the EC2 instance and security group
- retrieves the resulting public IP address

Terraform state is stored remotely in Amazon S3 with DynamoDB state locking.

### Bootstrap

Ansible connects to the newly created EC2 instance and:

- performs host bootstrap tasks
- installs k3s
- configures kubectl access
- installs Helm

### Deploy

The Helm chart is copied to the EC2 instance.

The image repository and Git-derived image tag from the build stage are supplied to Helm at deployment time.

Helm creates the Kubernetes application resources and waits for them to become ready.

### Verify

A smoke test connects to the application's public HTTP endpoint and checks that the expected OMK content is returned.

Example:

```text
Testing http://<EC2_PUBLIC_IP>...
OMK VERSION: 2
Smoke test passed
```

### Destroy

Infrastructure destruction is exposed as a manual GitLab CI job.

This allows the temporary AWS environment to be removed after testing.

## Application

The application is intentionally minimal: a static HTML page served by nginx.

The Docker image is based on:

```text
nginx:alpine
```

The simplicity of the application keeps the project focused on the DevOps workflow rather than application development.

## Kubernetes

The Helm chart creates:

- Deployment
- ReplicaSet
- two application Pods
- ClusterIP Service
- Ingress

Traefik is provided by k3s and handles incoming HTTP traffic.

The traffic path is:

```text
Internet
  ↓
EC2 public IP
  ↓
Traefik
  ↓
Ingress
  ↓
Service
  ↓
OMK Pods
```

## Configuration before first run

This repository contains environment-specific values that must be reviewed before deploying it in another AWS account or GitLab installation.

### Prerequisites

You need:

- an AWS account
- a GitLab installation or GitLab.com project
- a GitLab Runner using the Docker executor
- Docker access from the Runner
- an AWS EC2 SSH key pair
- an Amazon ECR Public repository
- an S3 bucket for Terraform state
- a DynamoDB table for Terraform state locking

The OMK Runner uses the host Docker daemon through:

```text
/var/run/docker.sock
```

The Docker socket therefore needs to be available inside the CI job containers that build images.

### GitLab CI/CD variables

Configure the following variables in the GitLab project:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_DEFAULT_REGION
TF_VAR_ssh_keypair_name
OMK_SSH_PRIVATE_KEY
```

Optional:

```text
OMK_SSH_USER
```

`OMK_SSH_USER` defaults to:

```text
ubuntu
```

`OMK_SSH_PRIVATE_KEY` should contain the private key matching the EC2 key pair referenced by `TF_VAR_ssh_keypair_name`.

### Terraform backend

Review:

```text
infra/terraform/envs/lab/backend.tf
```

and replace the project-specific values for:

```text
S3 state bucket
DynamoDB lock table
AWS region
```

with resources belonging to your own AWS account.

### Container registry

Create your own Amazon ECR Public repository and update the image repository used by the project.

Review:

```text
.gitlab-ci.yml
deploy/helm/omk-webapp/values.yaml
```

and replace the existing ECR Public repository URI with your own.

### EC2 SSH key

Create or import an EC2 key pair in the target AWS region.

Configure its AWS key-pair name as:

```text
TF_VAR_ssh_keypair_name
```

and configure the matching private key in GitLab as:

```text
OMK_SSH_PRIVATE_KEY
```

## Local smoke test

Once the application is deployed, it can also be tested manually:

```bash
./app/tests/smoke.sh http://<EC2_PUBLIC_IP>
```

Expected result:

```text
Testing http://<EC2_PUBLIC_IP>...
OMK VERSION: 2
Smoke test passed
```

## Infrastructure lifecycle

OMK is designed as an ephemeral lab environment.

A typical workflow is:

```text
change application
  ↓
git commit
  ↓
git push
  ↓
build image
  ↓
create/update infrastructure
  ↓
deploy application
  ↓
run smoke test
  ↓
destroy infrastructure
```

Rebuilding the environment is intentionally part of the normal workflow.

## Security notes

This is a learning environment and is not intended to represent a production-ready Kubernetes platform.

Some deliberate simplifications include:

- single-node Kubernetes
- public HTTP ingress
- SSH host-key checking disabled inside disposable CI jobs
- CI access to the host Docker daemon
- AWS IAM credentials supplied through GitLab CI/CD variables
- infrastructure destruction performed manually

SSH access to the EC2 instance is restricted dynamically to the public IP used by the CI environment.

HTTP and HTTPS access are exposed publicly for application testing.

The repository is configured to exclude common sensitive files such as:

```text
Terraform state
Terraform variable files
SSH private keys
kubeconfig files
environment files
local Terraform working directories
```

AWS credentials and private SSH keys must never be committed to the repository.

## Project status

OMK currently implements a complete automated application-delivery path:

```text
Source change
  ↓
Git push
  ↓
Docker image build
  ↓
Commit-SHA image tag
  ↓
ECR Public
  ↓
Terraform
  ↓
AWS EC2
  ↓
Ansible
  ↓
k3s
  ↓
Helm
  ↓
Traefik
  ↓
Application
  ↓
Smoke test
```

The complete AWS environment can then be removed using the manual Terraform destroy job.

## Purpose

OrangeMilk was created as a hands-on DevOps learning project.

Its purpose is to demonstrate how several commonly used DevOps technologies fit together into one functioning delivery system rather than to build a production-grade platform.

The project covers practical experience with:

- Git
- GitLab CI/CD
- Docker
- AWS
- Amazon ECR
- Terraform
- remote Terraform state
- Ansible
- Kubernetes
- k3s
- Helm
- Traefik
- CI artifacts
- CI environment-variable handoff
- infrastructure lifecycle management