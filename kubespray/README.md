# Kubernetes Setup on Hetzner using Kubespray

This guide explains how to deploy a **Kubernetes cluster on Hetzner Cloud using Kubespray and Ansible**.

The cluster architecture used in this setup consists of:

- **1 Jump Node / Master Node**
- **1 Control Plane Node**
- **2 Worker Nodes**
- **Private network for internal cluster communication**

Kubespray will be executed from the **jump node**, which will configure Kubernetes across all nodes using Ansible.

---

# Prerequisites

First connect to the **jump server** and prepare the environment.

```bash
ssh root@JUMP-SERVER-IP
Create a working directory and update the system:

mkdir kube-setup && cd kube-setup

apt update && apt upgrade -y
Installing Kubespray and Ansible
Clone the Kubespray repository:

git clone https://github.com/kubernetes-sigs/kubespray.git
Create a Python virtual environment and install the dependencies:

VENVDIR=kubespray-venv
KUBESPRAYDIR=kubespray

python3 -m venv $VENVDIR
source $VENVDIR/bin/activate

cd $KUBESPRAYDIR
pip install -U -r requirements.txt
cd ..
If the virtual environment module is not installed, install it with:

apt install python3-venv -y
Preparing the Cluster Configuration
Create the directory that will contain the cluster configuration:

mkdir -p clusters/eu-central
Generating the Inventory
We will use the internal IP addresses assigned by Terraform.

declare -a IPS=(172.16.0.101 172.16.0.102 172.16.0.103)

CONFIG_FILE=clusters/eu-central/hosts.yaml \
python3 kubespray/contrib/inventory_builder/inventory.py ${IPS[@]}
Navigate to the cluster configuration directory:

cd clusters/eu-central
Edit the generated hosts.yaml file so that it matches the node names used in Hetzner.

Example:

all:
  hosts:
    kube-node-1:
      ansible_host: 172.16.0.101
      ip: 172.16.0.101
      access_ip: 172.16.0.101

    kube-node-2:
      ansible_host: 172.16.0.102
      ip: 172.16.0.102
      access_ip: 172.16.0.102

    kube-node-3:
      ansible_host: 172.16.0.103
      ip: 172.16.0.103
      access_ip: 172.16.0.103

  children:

    kube_control_plane:
      hosts:
        kube-node-1:

    kube_node:
      hosts:
        kube-node-2:
        kube-node-3:

    etcd:
      hosts:
        kube-node-1:

    k8s_cluster:
      children:
        kube_control_plane:
        kube_node:

    calico_rr:
      hosts: {}
Cluster Custom Configuration
Create the cluster configuration file:

vi clusters/eu-central/cluster-config.yaml
Add the following configuration:

cloud_provider: external
external_cloud_provider: hcloud

external_hcloud_cloud:
  token_secret_name: hcloud-api-token
  with_networks: true
  service_account_name: hcloud-sa
  hcloud_api_token: <api-token>
  controller_image_tag: v1.16.0

kube_network_plugin: cilium
network_id: kubernetes-node-network
This configuration enables Hetzner as an external cloud provider and configures Cilium as the networking plugin.

Deploying the Kubernetes Cluster
Once the configuration is ready, deploy the cluster using the Kubespray playbook.

Navigate to the Kubespray directory:

cd kubespray
Run the Ansible playbook:

ansible-playbook \
-i ../clusters/eu-central/hosts.yaml \
-e @../clusters/eu-central/cluster-config.yaml \
--become --become-user=root \
cluster.yml
The installation may take several minutes as Kubespray installs all Kubernetes components across the nodes.

Troubleshooting: Nodes stuck in NotReady
After installation, nodes may appear in a NotReady state:

kubectl get nodes
Example:

NAME          STATUS     ROLES           AGE   VERSION
kube-node-1   NotReady   control-plane   ...
kube-node-2   NotReady   <none>          ...
kube-node-3   NotReady   <none>          ...
This can happen if CNI permissions are incorrect.

Fix it by running the following command from the jump node:

for node in 172.16.0.101 172.16.0.102 172.16.0.103; do
  ssh root@$node "chown -R root:root /opt/cni && chown -R root:root /opt/cni/bin"
done
Restart the Cilium daemonset:

kubectl -n kube-system rollout restart daemonset/cilium
Monitor the pods:

kubectl -n kube-system get pods -l k8s-app=cilium -w
Once the networking components are running, the nodes should transition to:

Ready
Connecting to the Cluster
Install kubectl on the jump node:

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

chmod +x kubectl
mv kubectl /usr/local/bin
Create the kubeconfig directory:

mkdir /root/.kube
Copy the configuration file from the control plane node:

scp root@172.16.0.101:/etc/kubernetes/admin.conf /root/.kube/config
Troubleshooting kubectl connection
If kubectl cannot connect to the cluster, verify the API server IP inside the kubeconfig file.

vi /root/.kube/config
Ensure the server address points to the control-plane node:

172.16.0.101
Verifying the Cluster
Check the nodes:

kubectl get nodes
Check the system pods:

kubectl -n kube-system get pods
```
