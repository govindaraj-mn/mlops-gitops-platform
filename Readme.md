# MLOps GitOps Platform for ML Workloads on AWS EKS

Production-oriented MLOps platform demonstrating Infrastructure as Code,
GitOps-based Kubernetes deployments, and observability for machine learning
workloads.

## Technology Stack

- AWS EKS
- Terraform
- Kubernetes
- Helm
- ArgoCD
- Prometheus
- Grafana
- Alertmanager
- Docker
- GitHub

## Architecture

The platform uses Terraform to provision reproducible AWS infrastructure,
Helm to package ML workloads, ArgoCD to continuously reconcile Kubernetes
deployments from Git, and Prometheus/Grafana/Alertmanager for monitoring
and alerting.

## Project Goals

- Reproducible AWS ML infrastructure
- Infrastructure as Code
- GitOps-based deployment
- Environment-specific configuration
- Automated deployment reconciliation
- Deployment rollback
- Kubernetes observability
- Production-oriented ML workload deployment

## Environments

- Development
- Staging
- Production

## Status

🚧 Under active development