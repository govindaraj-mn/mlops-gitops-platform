# MLOps GitOps Platform for ML Workloads on AWS EKS

A production-oriented MLOps platform for deploying, operating, monitoring, and recovering containerized machine learning workloads on **AWS EKS** using **Terraform, Kubernetes, Helm, Argo CD, GitHub Actions, Amazon ECR, Prometheus, Grafana, and Alertmanager**.

The project demonstrates an end-to-end engineering workflow in which infrastructure is defined as code, application changes are validated through CI, container images are versioned and stored in Amazon ECR, Git acts as the deployment source of truth, Argo CD continuously reconciles Kubernetes state, and observability provides operational visibility and alerting.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Problem Statement](#problem-statement)
- [Project Objectives](#project-objectives)
- [Architecture](#architecture)
- [End-to-End Deployment Flow](#end-to-end-deployment-flow)
- [Technology Stack](#technology-stack)
- [Infrastructure as Code](#infrastructure-as-code)
- [AWS Infrastructure](#aws-infrastructure)
- [ML Inference Service](#ml-inference-service)
- [Containerization](#containerization)
- [Amazon ECR](#amazon-ecr)
- [Kubernetes](#kubernetes)
- [Helm](#helm)
- [GitOps with Argo CD](#gitops-with-argo-cd)
- [CI with GitHub Actions](#ci-with-github-actions)
- [AWS OIDC Authentication](#aws-oidc-authentication)
- [Observability](#observability)
- [Alerting and Failure Recovery](#alerting-and-failure-recovery)
- [Testing and Validation](#testing-and-validation)
- [End-to-End Validation](#end-to-end-validation)
- [Repository Structure](#repository-structure)
- [Engineering Decisions](#engineering-decisions)
- [Challenges and Solutions](#challenges-and-solutions)
- [Security Considerations](#security-considerations)
- [Operational Workflow](#operational-workflow)
- [Current Implementation Status](#current-implementation-status)
- [Future Enhancements](#future-enhancements)
- [What This Project Demonstrates](#what-this-project-demonstrates)
- [Interview Explanation](#interview-explanation)
- [Author](#author)

---

# Project Overview

This project implements a complete **MLOps and GitOps deployment platform** for a containerized ML inference workload running on **Amazon EKS**.

The primary focus is not on building a sophisticated ML model itself, but on demonstrating the engineering systems required to move an ML service from source code to a running Kubernetes workload and then operate that workload using monitoring, alerting, and Git-based recovery.

The platform brings together:

- Infrastructure as Code
- Cloud infrastructure provisioning
- Containerization
- Container image management
- Kubernetes orchestration
- Helm-based application packaging
- Continuous Integration
- GitOps-based Continuous Delivery
- AWS identity federation using OIDC
- Metrics collection
- Dashboards
- Alerting
- Failure simulation
- Recovery validation
- Automated deployment reconciliation

The resulting workflow is:

```text
Developer
    │
    ▼
GitHub Repository
    │
    ▼
GitHub Actions
    │
    ├── Run tests
    ├── Build Docker image
    ├── Authenticate to AWS using OIDC
    ├── Push image to Amazon ECR
    └── Update Helm image tag in Git
              │
              ▼
       Git Repository
       Source of Truth
              │
              ▼
           Argo CD
              │
              ▼
          Amazon EKS
              │
              ▼
      ML Inference Service
              │
              ├──────────────► Prometheus
              │                     │
              │                     ▼
              │                  Grafana
              │
              └──────────────► Alertmanager
                                    │
                                    ▼
                                  Slack
```

---

# Problem Statement

Deploying an ML service to Kubernetes is only one part of operating a reliable ML platform.

A production-oriented workflow must also answer:

- How is infrastructure provisioned consistently?
- How are application changes tested?
- How are container images built and versioned?
- How are images securely pushed to a registry?
- How does Kubernetes know which version should run?
- How is the desired deployment state represented?
- How can deployments be reconciled automatically?
- How are application metrics collected?
- How are failures detected?
- How are alerts delivered?
- How is a failed deployment recovered?
- How can the entire process be reproduced?

This project addresses these questions by implementing an automated workflow around **Terraform + GitHub Actions + ECR + Git + Argo CD + Kubernetes + Prometheus/Grafana/Alertmanager**.

---

# Project Objectives

The platform was designed around the following objectives:

### Infrastructure

- Provision AWS infrastructure using Terraform.
- Create a reproducible Kubernetes environment using Amazon EKS.
- Separate infrastructure configuration from application deployment configuration.

### Application Delivery

- Package the ML inference service into a Docker image.
- Store versioned images in Amazon ECR.
- Use immutable Git commit SHAs as image tags.
- Automate image version updates in Helm configuration.

### CI/CD

- Automatically test application changes.
- Build and publish container images.
- Use Git as the deployment source of truth.
- Use Argo CD for Kubernetes deployment reconciliation.
- Avoid having CI directly manage Kubernetes application deployment.

### Observability

- Expose Prometheus metrics.
- Collect workload metrics.
- Visualize operational metrics through Grafana.
- Detect failures using Alertmanager.
- Deliver alerts to Slack.

### Reliability

- Simulate service failure.
- Validate alert firing.
- Validate alert resolution.
- Recover the service through the GitOps workflow.
- Verify that the final Kubernetes state matches the desired Git state.

---

# Architecture

## High-Level Architecture

```text
                         ┌──────────────────────┐
                         │      Developer       │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │       GitHub         │
                         │  Source Repository   │
                         └──────────┬───────────┘
                                    │
                              Push to main
                                    │
                                    ▼
                    ┌──────────────────────────────┐
                    │       GitHub Actions         │
                    │                              │
                    │  1. Install dependencies     │
                    │  2. Run tests                │
                    │  3. Build Docker image       │
                    │  4. Authenticate to AWS      │
                    │  5. Push image to ECR        │
                    │  6. Update Helm image tag    │
                    │  7. Commit change to Git     │
                    └──────────────┬───────────────┘
                                   │
                                   ▼
                         ┌──────────────────────┐
                         │    Git Repository    │
                         │  Desired State       │
                         └──────────┬───────────┘
                                    │
                                    │ GitOps reconciliation
                                    ▼
                         ┌──────────────────────┐
                         │       Argo CD        │
                         │  Continuous Delivery  │
                         └──────────┬───────────┘
                                    │
                                    ▼
                  ┌─────────────────────────────────┐
                  │          Amazon EKS              │
                  │                                 │
                  │   ┌─────────────────────────┐   │
                  │   │   ML Inference Service   │   │
                  │   │                         │   │
                  │   │   Kubernetes Deployment │   │
                  │   │   Kubernetes Service    │   │
                  │   │   ServiceMonitor        │   │
                  │   └────────────┬────────────┘   │
                  │                │                │
                  │                ▼                │
                  │        ┌──────────────┐         │
                  │        │  Prometheus  │         │
                  │        └──────┬───────┘         │
                  │               │                 │
                  │       ┌───────┴────────┐        │
                  │       ▼                ▼        │
                  │   ┌─────────┐   ┌────────────┐ │
                  │   │ Grafana │   │Alertmanager│ │
                  │   └─────────┘   └──────┬─────┘ │
                  │                         │       │
                  └─────────────────────────┼───────┘
                                            ▼
                                          Slack
```

---

# End-to-End Deployment Flow

The complete application delivery path is:

```text
1. Developer changes application code
              │
              ▼
2. Commit pushed to GitHub
              │
              ▼
3. GitHub Actions starts
              │
              ▼
4. Python dependencies installed
              │
              ▼
5. Automated tests executed
              │
        ┌─────┴─────┐
        │           │
      Fail        Pass
        │           │
        ▼           ▼
      Stop      Docker build
                    │
                    ▼
              ECR authentication
                    │
                    ▼
              Push image to ECR
                    │
                    ▼
          Update Helm image tag
                    │
                    ▼
          Commit Helm change to Git
                    │
                    ▼
              Argo CD detects
                Git change
                    │
                    ▼
            Kubernetes reconciliation
                    │
                    ▼
              EKS rolling update
                    │
                    ▼
             New application pod
                    │
                    ▼
             Health verification
```

The important architectural separation is:

```text
CI  = GitHub Actions
CD  = Argo CD
Runtime = Kubernetes / EKS
Source of Truth = Git
```

GitHub Actions does **not** directly deploy the application to EKS.

Instead, CI produces the container artifact and updates the desired state in Git. Argo CD is responsible for reconciling that desired state with the Kubernetes cluster.

---

# Technology Stack

| Layer | Technology | Purpose |
|---|---|---|
| Cloud | AWS | Cloud infrastructure |
| Infrastructure as Code | Terraform | Reproducible infrastructure |
| Compute | Amazon EKS | Kubernetes control plane |
| Container Runtime | Docker | Application containerization |
| Registry | Amazon ECR | Container image storage |
| Orchestration | Kubernetes | Workload management |
| Packaging | Helm | Kubernetes application packaging |
| GitOps | Argo CD | Continuous deployment/reconciliation |
| CI | GitHub Actions | Testing, image build and publishing |
| Authentication | AWS IAM + OIDC | Secure GitHub-to-AWS authentication |
| Metrics | Prometheus | Metrics collection |
| Visualization | Grafana | Monitoring dashboards |
| Alerting | Alertmanager | Alert routing |
| Notifications | Slack | Operational notifications |
| Application | FastAPI | ML inference API |
| Testing | Pytest | Automated application testing |
| Language | Python | Application implementation |

---

# Infrastructure as Code

Terraform is used to provision the AWS infrastructure required by the platform.

The infrastructure is organized into reusable modules.

```text
terraform/
├── environments/
│   └── dev/
│       ├── main.tf
│       ├── outputs.tf
│       ├── providers.tf
│       ├── variables.tf
│       └── versions.tf
│
└── modules/
    ├── eks/
    ├── iam/
    └── vpc/
```

## Terraform Modules

### VPC Module

Responsible for the networking foundation required by EKS.

### EKS Module

Responsible for creating the Kubernetes cluster and associated compute resources.

### IAM Module

Responsible for IAM resources required by the platform, including the GitHub Actions AWS role.

---

# AWS Infrastructure

The platform runs on Amazon EKS in AWS.

The implemented environment includes:

- VPC networking
- Subnets
- Amazon EKS
- EKS worker capacity
- IAM roles
- GitHub Actions OIDC identity provider
- GitHub Actions IAM role
- Amazon ECR repository

The implementation uses AWS region:

```text
ap-south-1
```

The EKS cluster is:

```text
mlops-dev-eks
```

The ECR repository is:

```text
ml-inference
```

---

# ML Inference Service

The application is implemented using **FastAPI**.

The service provides endpoints for:

- Health checking
- Prediction/inference
- Prometheus metrics

The application is intentionally lightweight because the primary goal of the project is to demonstrate the **production engineering lifecycle around an ML workload**.

Example health response:

```json
{
  "status": "healthy",
  "version": "phase-2-e2e-test"
}
```

The version information provides a simple way to verify which application build is currently running inside Kubernetes.

---

# Containerization

The application is packaged as a Docker image.

The Dockerfile is located at:

```text
app/Dockerfile
```

The container image contains:

- Python runtime
- Application dependencies
- FastAPI application
- Uvicorn server

The image is built using the Git commit SHA as the image tag.

Example:

```text
ml-inference:<commit-sha>
```

This creates a direct relationship between:

```text
Git commit
      ↓
Docker image
      ↓
Helm deployment
      ↓
Kubernetes workload
```

This improves traceability because a deployed container can be mapped back to the exact source commit that produced it.

---

# Amazon ECR

Amazon Elastic Container Registry is used as the private container registry.

The CI workflow:

1. Authenticates to AWS.
2. Authenticates Docker to ECR.
3. Builds the application image.
4. Tags the image using the Git commit SHA.
5. Pushes the image to ECR.

Example:

```text
724793286760.dkr.ecr.ap-south-1.amazonaws.com/ml-inference:<commit-sha>
```

Using commit SHAs instead of mutable tags such as:

```text
latest
```

makes deployments more traceable and reduces ambiguity about which application version is running.

---

# Kubernetes

The ML workload runs on Kubernetes inside Amazon EKS.

The deployment includes:

- Kubernetes Deployment
- Kubernetes Service
- Prometheus ServiceMonitor

The application is deployed into the:

```text
ml-inference
```

namespace.

The Kubernetes Deployment manages application replicas and rolling updates.

The Kubernetes Service provides stable internal access to the workload.

---

# Helm

Helm is used to package and parameterize the Kubernetes application.

The Helm chart is located at:

```text
helm/ml-inference/
```

Structure:

```text
helm/ml-inference/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    └── servicemonitor.yaml
```

The main configurable values include:

```yaml
replicaCount: 2

image:
  repository: ...
  tag: ...
  pullPolicy: IfNotPresent
```

The CI pipeline automatically updates the image tag:

```yaml
tag: "<github-sha>"
```

This means the Helm configuration represents the exact application version that should be deployed.

---

# GitOps with Argo CD

Argo CD provides the Continuous Delivery layer.

The Argo CD Application definition is stored in:

```text
kubernetes/argocd/ml-inference.yaml
```

Argo CD monitors:

```text
GitHub Repository
        ↓
helm/ml-inference
```

and continuously reconciles the Kubernetes cluster with the desired state defined in Git.

The configured synchronization policy enables:

```text
automated sync
prune
selfHeal
CreateNamespace
```

Conceptually:

```text
Git
 │
 │ Desired State
 ▼
Argo CD
 │
 │ Reconciliation
 ▼
Kubernetes
```

This creates a clear separation between:

- CI responsibility
- CD responsibility
- runtime responsibility

---

# CI with GitHub Actions

GitHub Actions provides the CI workflow.

The workflow is triggered by changes to the repository, including pushes to `main`. GitHub exposes the commit associated with the push through `GITHUB_SHA`, which is used here as the image version. citeturn0search5turn0search6

The workflow performs the following operations:

```text
Checkout source
      ↓
Configure AWS credentials
      ↓
Verify AWS identity
      ↓
Login to ECR
      ↓
Setup Python
      ↓
Install dependencies
      ↓
Run pytest
      ↓
Build Docker image
      ↓
Tag image with Git SHA
      ↓
Push image to ECR
      ↓
Update Helm image tag
      ↓
Commit Helm change
      ↓
Push change to Git
      ↓
Argo CD reconciles
```

## Testing Gate

The workflow runs:

```bash
python -m pytest -v
```

If tests fail, the pipeline stops before the image is published as part of the successful delivery flow.

This provides a basic quality gate between source changes and deployment artifacts.

---

# Git as the Deployment Source of Truth

One of the most important architectural decisions in the project is:

> **Git represents the desired deployment state.**

The deployment version is stored in:

```text
helm/ml-inference/values.yaml
```

For example:

```yaml
image:
  repository: 724793286760.dkr.ecr.ap-south-1.amazonaws.com/ml-inference
  tag: "<commit-sha>"
```

GitHub Actions updates this value after successfully building and pushing the image.

Argo CD then observes the Git change and reconciles the Kubernetes environment.

This produces:

```text
Application Source
       ↓
GitHub Actions
       ↓
Container Image
       ↓
ECR
       ↓
Helm desired state
       ↓
Git
       ↓
Argo CD
       ↓
EKS
```

---

# AWS OIDC Authentication

The GitHub Actions workflow authenticates to AWS using **OpenID Connect (OIDC)** rather than storing long-lived AWS access keys in GitHub secrets.

GitHub's OIDC model allows a workflow to obtain an identity token and exchange it with AWS for short-lived credentials. GitHub recommends restricting the AWS trust relationship using token claims such as the `sub` claim so that only intended repositories/workflows can assume the role. citeturn0search0turn0search1

The workflow grants:

```yaml
permissions:
  id-token: write
  contents: write
```

The:

```text
id-token: write
```

permission allows the workflow to request the GitHub OIDC token; it does not itself grant AWS resource permissions. AWS IAM determines what the assumed role can actually access. citeturn0search0

The IAM trust policy restricts access to the intended GitHub repository identity and branch.

The project also uses GitHub's immutable repository/owner identifiers in the OIDC subject condition, matching the current GitHub OIDC model for repositories using immutable subject claims. citeturn0search0turn0search3

This provides a stronger security model than storing static AWS credentials in repository secrets.

---

# IAM Permissions

The GitHub Actions IAM role is intentionally scoped around the resources required by the CI workflow.

The workflow requires permissions to:

- Authenticate to AWS.
- Obtain an ECR authorization token.
- Push container layers.
- Publish the container image.

The ECR repository permissions are scoped to the ML inference repository rather than granting unrestricted ECR access.

This follows the principle of least privilege as closely as practical for the implemented workflow.

---

# Observability

Observability is an important part of the platform rather than an afterthought.

The application exposes Prometheus-compatible metrics.

The Helm chart includes a:

```text
ServiceMonitor
```

which allows Prometheus to discover and scrape the application metrics.

The observability stack consists of:

```text
ML Service
    │
    ▼
Prometheus
    │
    ├──────────────► Grafana
    │
    └──────────────► Alertmanager
                          │
                          ▼
                        Slack
```

---

# Prometheus

Prometheus is responsible for collecting application and Kubernetes-related metrics.

The application exposes metrics through the metrics endpoint.

The ServiceMonitor provides the monitoring configuration required for Prometheus discovery.

This allows the application to participate in Kubernetes-native monitoring rather than relying on external polling.

---

# Grafana

Grafana provides visualization of operational metrics.

The project includes dashboard provisioning so that monitoring configuration can be maintained as code rather than manually configured only through the Grafana UI.

The dashboard provides visibility into the running ML workload and its operational behavior.

---

# Alertmanager

Alertmanager is responsible for processing and routing Prometheus alerts.

The alerting workflow is:

```text
Prometheus
    │
    │ Alert rule triggered
    ▼
Alertmanager
    │
    ▼
Slack
```

This provides a separation between:

- metric collection
- alert evaluation
- notification delivery

---

# Alerting and Failure Recovery

The platform includes a failure simulation and recovery workflow.

The purpose is to demonstrate that the platform can detect operational problems rather than only deploy applications successfully.

The tested lifecycle is:

```text
Healthy Service
      │
      ▼
Failure Introduced
      │
      ▼
Prometheus detects condition
      │
      ▼
Alert fires
      │
      ▼
Alertmanager
      │
      ▼
Slack notification
      │
      ▼
Failure resolved
      │
      ▼
Prometheus condition clears
      │
      ▼
Alert resolves
```

The recovery process is Git-based.

Rather than manually modifying the Kubernetes deployment as the normal recovery mechanism, the desired configuration is restored through Git and Argo CD reconciles the cluster back to the declared state.

This reinforces the GitOps operating model.

---

# Testing and Validation

The project includes automated application tests using Pytest.

The test suite validates:

- Health endpoint
- Prediction endpoint
- Metrics endpoint

Example test execution:

```bash
python -m pytest -v
```

The implemented test suite successfully validated:

```text
3 passed
```

There were dependency-related deprecation warnings during local testing, but they did not cause test failures.

---

# End-to-End Validation

The complete deployment workflow was validated from source change through live Kubernetes execution.

The validation covered:

```text
Application change
       ↓
Git commit
       ↓
GitHub Actions
       ↓
Automated tests
       ↓
Docker build
       ↓
ECR push
       ↓
Helm image tag update
       ↓
Git commit
       ↓
Argo CD synchronization
       ↓
EKS deployment
       ↓
Running application
       ↓
Health verification
```

The deployed application image was verified using the Git commit SHA.

The running application returned:

```json
{
  "status": "healthy",
  "version": "phase-2-e2e-test"
}
```

The final Argo CD state was:

```text
NAME           SYNC STATUS   HEALTH STATUS
ml-inference   Synced        Healthy
```

This demonstrates that the complete delivery chain was not only designed but actually exercised end-to-end.

---

# Repository Structure

```text
mlops-gitops-platform/
│
├── app/
│   ├── Dockerfile
│   └── src/
│       └── main.py
│
├── helm/
│   └── ml-inference/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           └── servicemonitor.yaml
│
├── kubernetes/
│   └── argocd/
│       └── ml-inference.yaml
│
├── monitoring/
│   ├── prometheus/
│   ├── grafana/
│   └── alertmanager/
│
├── terraform/
│   ├── environments/
│   │   └── dev/
│   │       ├── main.tf
│   │       ├── outputs.tf
│   │       ├── providers.tf
│   │       ├── variables.tf
│   │       └── versions.tf
│   │
│   └── modules/
│       ├── eks/
│       ├── iam/
│       └── vpc/
│
├── tests/
│   └── test_api.py
│
├── requirements.txt
├── .gitignore
└── Readme.md
```

---

# Engineering Decisions

## 1. Terraform for Infrastructure

Terraform was selected to ensure that cloud infrastructure is reproducible and version controlled.

Instead of manually creating AWS resources, infrastructure changes are represented as code.

---

## 2. GitOps Instead of Direct Kubernetes Deployment from CI

A key architectural decision was to avoid having GitHub Actions directly deploy the application to EKS.

Instead:

```text
GitHub Actions
      ↓
Update Git
      ↓
Argo CD
      ↓
EKS
```

This creates a cleaner separation between CI and CD and makes Git the auditable desired-state repository.

---

## 3. Immutable Image Versioning

The Docker image uses the Git commit SHA as its tag.

Instead of:

```text
latest
```

the deployment references:

```text
<commit-sha>
```

This makes it possible to trace:

```text
Running Pod
    ↓
Container Image
    ↓
Git Commit
    ↓
Source Code
```

---

## 4. Helm for Kubernetes Packaging

Helm separates application configuration from Kubernetes resource templates.

This makes deployment configuration easier to maintain and provides a clean interface for CI to update the image version.

---

## 5. OIDC Instead of Static AWS Credentials

GitHub Actions authenticates to AWS using OIDC.

This avoids storing long-lived AWS access keys in GitHub and allows IAM to control which GitHub identity can assume the AWS role. citeturn0search0turn0search1

---

## 6. Monitoring as Code

Monitoring configuration is maintained in Git.

This includes:

- ServiceMonitor configuration
- Grafana provisioning
- Alertmanager configuration

This follows the same version-controlled approach used for infrastructure and application deployment.

---

# Challenges and Solutions

## Challenge 1 — Keeping Infrastructure Reproducible

### Problem

Manual AWS configuration can result in configuration drift and makes environments difficult to reproduce.

### Solution

Terraform modules were used to define:

- VPC
- EKS
- IAM

Infrastructure changes can therefore be reviewed and applied through Terraform.

---

## Challenge 2 — Secure CI Authentication to AWS

### Problem

GitHub Actions needs AWS access to push container images to ECR.

Using permanent AWS access keys would introduce long-lived credentials into the CI environment.

### Solution

GitHub Actions OIDC was implemented.

The workflow obtains a GitHub identity token and assumes a restricted AWS IAM role using web identity federation. citeturn0search0

---

## Challenge 3 — Separating CI from CD

### Problem

A CI pipeline that directly executes:

```text
kubectl apply
```

creates tight coupling between CI and the Kubernetes cluster.

### Solution

GitHub Actions updates the desired image version in Git.

Argo CD then handles deployment reconciliation.

This results in:

```text
CI → Git
CD → Argo CD
Runtime → EKS
```

---

## Challenge 4 — Tracking Which Application Version Is Running

### Problem

Using mutable image tags such as `latest` makes it difficult to identify the exact version running in Kubernetes.

### Solution

The Git commit SHA is used as the Docker image tag.

This provides deterministic traceability from deployment back to source code.

---

## Challenge 5 — Detecting Runtime Failures

### Problem

A deployment pipeline can succeed while the application later becomes unhealthy.

### Solution

Prometheus, Grafana, and Alertmanager were integrated into the platform.

Failure simulation was used to validate:

```text
Failure
  ↓
Metric/condition
  ↓
Prometheus
  ↓
Alertmanager
  ↓
Slack
```

and the corresponding recovery lifecycle.

---

## Challenge 6 — Git and Automated Image Updates

The CI workflow updates the Helm image tag and commits that change back to `main`.

This is intentional because the Git repository represents the desired deployment state.

However, it introduces an operational consideration: because the workflow is triggered by pushes to `main`, an automation-generated commit can itself result in another workflow run. GitHub Actions supports branch-specific `push` triggers, so workflow design must account for this behavior. citeturn0search5turn0search6

This is an area identified for further workflow optimization.

---

## Challenge 7 — EKS API Access During Development

During development, the EKS API public-access CIDR needed to match the current development workstation IP.

When the public IP changed, Terraform and Kubernetes access had to be reconciled.

The issue was resolved by updating the Terraform configuration and applying the EKS cluster configuration change.

This reinforced an important operational principle:

> Network access configuration should be treated as infrastructure code rather than manually changed outside Terraform.

---

# Security Considerations

The project incorporates several security-oriented practices.

### AWS Authentication

GitHub Actions uses OIDC rather than long-lived AWS access keys. citeturn0search0

### IAM Trust Restrictions

The GitHub OIDC trust policy restricts which repository identity can assume the AWS role.

### Least Privilege

ECR permissions are scoped around the repository required by the application.

### No AWS Credentials in Source

Long-lived AWS credentials are not stored in the repository.

### Immutable Image References

Container images are referenced using Git commit SHAs instead of mutable `latest` tags.

### Git as Audit Trail

Deployment changes are represented through Git commits, creating an auditable history of desired application versions.

---

# Operational Workflow

A normal application change follows this process:

### Step 1 — Developer changes application

Example:

```text
app/src/main.py
```

### Step 2 — Run tests locally

```bash
python -m pytest -v
```

### Step 3 — Commit and push

```bash
git add .
git commit -m "Update inference service"
git push
```

### Step 4 — GitHub Actions starts

The workflow:

- installs dependencies
- runs tests
- builds the Docker image
- authenticates to AWS
- pushes the image to ECR

### Step 5 — Helm configuration is updated

The image tag becomes the Git commit SHA.

### Step 6 — Git is updated

The Helm change is committed to the repository.

### Step 7 — Argo CD detects the change

Argo CD compares:

```text
Git desired state
        vs
Kubernetes actual state
```

### Step 8 — Kubernetes reconciles

The EKS deployment performs the required rolling update.

### Step 9 — Application is verified

The health endpoint is checked.

### Step 10 — Monitoring continues

Prometheus collects metrics and Grafana provides visualization.

If an operational condition triggers an alert:

```text
Prometheus → Alertmanager → Slack
```

---

# Current Implementation Status

The core platform is implemented and end-to-end validated.

### Infrastructure

- [x] Terraform VPC
- [x] Terraform EKS
- [x] Terraform IAM
- [x] AWS ECR
- [x] GitHub OIDC
- [x] IAM trust configuration

### Application

- [x] FastAPI inference service
- [x] Health endpoint
- [x] Prediction endpoint
- [x] Prometheus metrics
- [x] Docker image

### Kubernetes

- [x] EKS deployment
- [x] Kubernetes Service
- [x] Helm chart
- [x] ServiceMonitor
- [x] Rolling deployment

### GitOps

- [x] Argo CD
- [x] Git-based desired state
- [x] Automated synchronization
- [x] Self-healing
- [x] Pruning
- [x] Git-based recovery

### CI

- [x] GitHub Actions
- [x] Automated tests
- [x] Docker build
- [x] ECR push
- [x] Helm image update
- [x] Git commit/push

### Observability

- [x] Prometheus
- [x] Grafana
- [x] Alertmanager
- [x] Slack notifications
- [x] Failure simulation
- [x] Alert firing/resolution validation

### End-to-End

- [x] Source change → CI
- [x] CI → ECR
- [x] CI → Git
- [x] Git → Argo CD
- [x] Argo CD → EKS
- [x] EKS → running application
- [x] Live health verification

---

# Future Enhancements

The current implementation intentionally focuses on the core MLOps/GitOps platform.

Potential future improvements include:

## CI/CD Improvements

- Separate CI and GitOps update workflows.
- Prevent unnecessary workflow recursion from automation-generated commits.
- Add pull-request quality gates.
- Add container vulnerability scanning.
- Add Kubernetes manifest validation.
- Add Helm linting and chart tests.

## Deployment Improvements

- Add environment promotion workflows.
- Add staging and production environments.
- Add progressive delivery.
- Add canary deployments.
- Add blue/green deployment strategies.
- Introduce automated rollback policies where appropriate.

## ML Platform Improvements

- Add model artifact versioning.
- Add model registry integration.
- Add model evaluation gates.
- Add model performance monitoring.
- Add data drift detection.
- Add model drift detection.
- Add experiment tracking.

## Infrastructure Improvements

- Add remote Terraform state management.
- Add stronger environment isolation.
- Add private EKS endpoint patterns.
- Add additional AWS security controls.
- Add policy-as-code validation.

---

# What This Project Demonstrates

This project demonstrates practical understanding of the engineering lifecycle required to operate ML workloads in a cloud-native environment.

### Cloud Engineering

- AWS
- EKS
- ECR
- IAM
- VPC
- Cloud networking

### Infrastructure Engineering

- Terraform
- Modular infrastructure
- Infrastructure state management
- Infrastructure reproducibility

### Kubernetes Engineering

- Deployments
- Services
- Namespaces
- Rolling updates
- ServiceMonitor
- Helm

### DevOps / CI/CD

- GitHub Actions
- Automated testing
- Docker builds
- Artifact publishing
- Git-based deployment workflows

### GitOps

- Argo CD
- Desired-state management
- Automated reconciliation
- Self-healing
- Git-based recovery

### Security

- AWS IAM
- OIDC federation
- Short-lived credentials
- Least privilege
- Repository-scoped trust

### Observability

- Prometheus
- Grafana
- Alertmanager
- Slack
- Failure detection
- Alert lifecycle validation

### MLOps

- ML inference service
- Containerized ML workload
- Reproducible deployment
- Version traceability
- Operational monitoring

---

# Interview Explanation

A concise way to explain the project in an interview is:

> **"I built a production-oriented MLOps and GitOps platform for deploying a containerized ML inference service on AWS EKS. Terraform provisions the AWS infrastructure, including the VPC, EKS, and IAM components. The application is containerized with Docker and stored in Amazon ECR. GitHub Actions handles CI by running tests, building the image, authenticating to AWS using OIDC, and publishing the image. The image is tagged with the Git commit SHA for traceability.**
>
> **Instead of having CI directly deploy to Kubernetes, the pipeline updates the Helm image tag in Git. Git becomes the source of truth for the desired deployment state, and Argo CD continuously reconciles that state into EKS. This gives me a clear separation between CI and CD.**
>
> **For observability, I integrated Prometheus, Grafana, and Alertmanager. The application exposes metrics through a ServiceMonitor, Grafana provides dashboards, and Alertmanager sends notifications to Slack. I also simulated failures and validated the alert lifecycle from FIRING to RESOLVED and verified Git-based recovery.**
>
> **Finally, I validated the complete flow end-to-end: application change → GitHub Actions → tests → Docker build → ECR → Git update → Argo CD → EKS → live application health verification. The final Kubernetes state was verified as Synced and Healthy in Argo CD."**

---

# Key Interview Talking Points

If asked **"Why GitOps?"**

> GitOps makes Git the source of truth for the desired deployment state. It provides auditability, repeatability, and a clean separation between CI and CD. Instead of CI directly changing the cluster, Argo CD reconciles the Kubernetes environment with the state declared in Git.

---

If asked **"Why Argo CD?"**

> Argo CD continuously compares the desired state in Git with the actual Kubernetes state and reconciles differences automatically. This gives the platform automated deployment synchronization and self-healing behavior.

---

If asked **"Why use the Git SHA as the image tag?"**

> It creates immutable and traceable application versions. I can identify the exact Git commit associated with a running container instead of relying on a mutable tag such as `latest`.

---

If asked **"Why OIDC?"**

> OIDC avoids storing long-lived AWS credentials in GitHub. GitHub Actions obtains an identity token and exchanges it with AWS for short-lived credentials, while IAM controls which GitHub identity is allowed to assume the role. citeturn0search0turn0search1

---

If asked **"Does GitHub Actions deploy directly to EKS?"**

> No. GitHub Actions handles CI and updates the desired Helm configuration in Git. Argo CD handles the actual Kubernetes deployment and reconciliation.

---

If asked **"How do you recover from a deployment problem?"**

> The desired state is restored in Git, and Argo CD reconciles the cluster back to that state. This keeps recovery aligned with the GitOps model instead of relying on undocumented manual cluster changes.

---

If asked **"How did you validate the platform?"**

> I validated the complete delivery chain rather than testing individual components in isolation. I changed the application, pushed the commit, verified GitHub Actions tests and image publishing, verified the Helm image update, confirmed Argo CD synchronization, checked the running EKS workload, and validated the live application health response.

---

# Project Outcome

The project demonstrates a complete cloud-native delivery and operations workflow for an ML workload:

```text
                    SOURCE
                      │
                      ▼
                   GitHub
                      │
                      ▼
                     CI
               GitHub Actions
                      │
          ┌───────────┴───────────┐
          ▼                       ▼
       Tests                  Docker Build
                                  │
                                  ▼
                                ECR
                                  │
                                  ▼
                         Helm Image Version
                                  │
                                  ▼
                               GitOps
                                  │
                                  ▼
                              Argo CD
                                  │
                                  ▼
                                EKS
                                  │
                                  ▼
                         ML Inference API
                                  │
                     ┌────────────┴────────────┐
                     ▼                         ▼
                 Prometheus                Application
                     │                     Metrics
               ┌─────┴─────┐
               ▼           ▼
            Grafana    Alertmanager
                           │
                           ▼
                         Slack
```

The resulting platform provides:

- Reproducible infrastructure
- Automated application testing
- Containerized ML workloads
- Versioned container artifacts
- Secure AWS authentication
- Git-based deployment state
- Automated Kubernetes reconciliation
- Self-healing GitOps behavior
- Operational dashboards
- Alerting
- Failure detection
- Git-based recovery
- End-to-end deployment traceability

---

# Author

**Govind Raj**

AI Engineer focused on:

- AI/ML Engineering
- NLP
- RAG & LLM Applications
- MLOps
- Kubernetes
- Cloud-native AI systems
- Production-oriented AI platforms

GitHub:

**govindaraj-mn**

---

## Project Repository

**MLOps GitOps Platform**

`https://github.com/govindaraj-mn/mlops-gitops-platform`

---