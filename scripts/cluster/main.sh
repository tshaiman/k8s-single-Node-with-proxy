#!/bin/bash

export SQUID_NOAUTH_IP=$1

#######################################
echo "Deploy K8s Single Node KubeAdm cluster"
#########################################
sudo -i
bash <(curl -s https://raw.githubusercontent.com/tshaiman/k8s-single-Node-with-proxy/main/scripts/cluster/install_master.sh)

echo "Remove Taints on master node"
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

echo "Patch Kube config"
mkdir -p /home/azureuser/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/azureuser/.kube/config
sudo chown azureuser:azureuser /home/azureuser/.kube/config

#################################################
echo "Install Utils"
################################################

###############################
echo "patch kubectl aliases"
###############################
wget https://raw.githubusercontent.com/tshaiman/proxy-simulation/main/scripts/config/bash_aliases
cat ./bash_aliases | tee ~/.bash_aliases

###############################
# Install Azure CLI
###############################
sudo apt-get update
sudo apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg

curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list

sudo apt-get update
sudo apt-get install -y azure-cli

az extension add --name connectedk8s --yes

az extension add --name k8sconfiguration --yes

az extension add --name k8s-extension --yes

cp -R $HOME/.azure /home/azureuser
sudo chown -R azureuser:azureuser /home/azureuser

# Install Helm 3
echo "install helm"
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh


###############################
echo "Install Ingress Nginx Controller"
kubectl apply -f https://raw.githubusercontent.com/tshaiman/proxy-simulation/main/manifests/ingress-ngxin-baremetal.yaml
###############################

###############################
echo "Install Local-Path Provisioner and set it as default"
############################### 
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

############################### 
echo "apply Network Policy"
###############################
echo "Donwload simulation.yaml"
wget https://raw.githubusercontent.com/tshaiman/proxy-simulation/main/manifests/simulation.yaml
perl -i -pe "s/<SQUID_NOAUTH_IP>/$(echo -n $SQUID_NOAUTH_IP)/g" simulation.yaml
cp simulation.yaml /home/azureuser/simulation.yaml

##unmakr this if you want to have a simulation traffic using calico GloblaNetworkPolicy
#kubectl apply -f simulation.yaml
