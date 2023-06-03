# k8s-single-Node-with-proxy
create a single Node K8s Kubeadm cluster with Proxy Server on Azure.

## Purpose: 
1. Deploys single Node K8s Kubeadm cluster that is capable of running Azure Arc enabled Kubernetes
2. Deploys Proxy Server on another VM to allow external traffic to go through the proxy
## Prerequisites
- Azure Subscription
- terraform CLI

## Steps
- run `terraform init`
- run `terraform plan`
- run `terraform apply -auto-approve`

## Note :
- This will create D8a_V4 VM with 4 CPU and 16 GB RAM on your Azure Subscription
- Deploys Proxy Server on another VM with 2 CPU and 8 GB RAM
- Apply the proxy settings on the Proxy VM using Squid
- Install kubectl, kubelet and kubeadm on the Cluster VM 
- Installs Azure CLI on the Cluster VM as well as Azure ARC Agent

