# Kubernetes setup with Kubespray

[](https://github.com/morrismusumi/kubernetes/tree/main/cloud/hetzner/kubespray#kubernetes-setup-with-kubespray)

## Prerequisites

[](https://github.com/morrismusumi/kubernetes/tree/main/cloud/hetzner/kubespray#prerequisites)

Login to the jump-server and create the project directory and upgrade all system dependencies

```shell
$ ssh root@JUMP-SERVER-IP

$ mkdir kube-setup && cd kube-setup

$ sudo apt update && sudo apt upgrade -y
```

Clone the kubespray repository and install Ansible

```shell
$ git clone https://github.com/kubernetes-sigs/kubespray.git

$ VENVDIR=kubespray-venv
$ KUBESPRAYDIR=kubespray
$ python3 -m venv $VENVDIR
$ source $VENVDIR/bin/activate
$ cd $KUBESPRAYDIR
$ pip install -U -r requirements.txt
$ cd ..

```

If you dont have python-venv install it with apt install python3-venv -y

##

Preparing the necessary files

[](https://github.com/morrismusumi/kubernetes/tree/main/cloud/hetzner/kubespray#preparing-the-necessary-files)

Create the cluster configuration directory

```shell
$ mkdir -p clusters/eu-central
```

Generate the inventory file.

```shell
$ declare -a IPS=(172.16.0.101 172.16.0.102 172.16.0.103)
$ CONFIG_FILE=clusters/eu-central/hosts.yaml python3 kubespray/contrib/inventory_builder/inventory.py ${IPS[@]}

Go to the following path:

```

cd /kube-setup/clusters/eu-central

And there create a hosts.yaml with:

```yaml
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

# Edit the hosts.yaml file and match the name of the nodes to the server names in hetzner
```

$ vi clusters/eu-central/hosts.yaml

Create the cluster custom configuration file with the contents below

```shell
$ vi clusters/eu-central/cluster-config.yaml

# Custom cofiguration options for hcloud as a cloud provider
$ cat clusters/eu-central/cluster-config.yaml

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
```

## Deploying the Cluster

[](https://github.com/morrismusumi/kubernetes/tree/main/cloud/hetzner/kubespray#deploying-the-cluster)

Deploy a new kubernetes cluster

```shell
$ cd kubespray
$ ansible-playbook -i ../clusters/eu-central/hosts.yaml -e @../clusters/eu-central/cluster-config.yaml --become --become-user=root cluster.yml
```

## Connecting to the Cluster

[](https://github.com/morrismusumi/kubernetes/tree/main/cloud/hetzner/kubespray#connecting-to-the-cluster)

Install kubectl.

```shell
$ curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
$ chmod +x kubectl
$ mv kubectl /usr/local/bin
```

Copy the KUBECONFIG file from one of the control-plane nodes

```shell
$ mkdir /root/.kube
$ scp root@172.16.0.101:/etc/kubernetes/admin.conf /root/.kube/config

# Edit the config file IP address and set it to the IP of the master node
$ vi /root/.kube/config

# Test the connection to the cluster
$ kubectl get nodes

# Check that the cluster control-plane components are running
$ kubectl -n kube-system get pods
```
