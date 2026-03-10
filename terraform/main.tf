# ========================================
# Hetzner Cloud Kubernetes Infrastructure
# ========================================
# 
# This Terraform configuration sets up a Kubernetes cluster on Hetzner Cloud with:
# - 1 Master node (kubernetes-master)
# - 3 Worker nodes (kube-node-1, kube-node-2, kube-node-3)
# - Private network configuration with subnet
# - SSH key management for secure access
#
# NETWORK CONFIGURATION:
# - Network: 172.16.0.0/24 (kubernetes-node-network)
# - Subnet: 172.16.0.0/24 in eu-central zone
# - Master IP: 172.16.0.100
# - Worker IPs: 172.16.0.101, 172.16.0.102, 172.16.0.103
#
# SERVER SPECIFICATIONS:
# - Image: Ubuntu 24.04
# - Type: cx23 (2 vCPU, 4 GB RAM)
# - Location: hel1 (Helsinki)
# - IPv4: Enabled
# - IPv6: Disabled
#
# SSH ACCESS:
# - Master node: SSH_KEY only
# - Worker nodes: SSH_KEY + SSH_KEY_MASTER_SERVER
#
# DEPENDENCIES:
# All server resources depend on the creation of kubernetes-node-subnet
# to ensure proper network initialization before server deployment.
resource "hcloud_server" "kubernetes-master" {
  name = "kubernetes-master"
  image = "ubuntu-24.04"
  server_type = "cx23"
  location = "hel1"
  ssh_keys = [ "SSH_KEY" ]
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  network {
    network_id = hcloud_network.kubernetes-node-network.id
    ip = "172.16.0.100"
  }

  depends_on = [ hcloud_network_subnet.kubernetes-node-subnet ]
}

resource "hcloud_server" "kube-node" {
  count = 3
  name = "kube-node-${count.index + 1}"
  image = "ubuntu-24.04"
  server_type = "cx23"
  location = "hel1"
  ssh_keys = [ "SSH_KEY", "SSH_KEY_MASTER_SERVER" ]
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  network {
    network_id = hcloud_network.kubernetes-node-network.id
    ip = "172.16.0.10${count.index + 1}"
  }

  depends_on = [ hcloud_network_subnet.kubernetes-node-subnet ]
}

resource "hcloud_network" "kubernetes-node-network" {
  name = "kubernetes-node-network"
  ip_range = "172.16.0.0/24"
}

resource "hcloud_network_subnet" "kubernetes-node-subnet" {
  type = "cloud"
  network_id = hcloud_network.kubernetes-node-network.id
  network_zone = "eu-central"
  ip_range = "172.16.0.0/24"
}

resource "hcloud_ssh_key" "default" {
  name = "SSH_KEY"
  public_key = var.SSH_KEY
}
resource "hcloud_ssh_key" "master-node" {
  name = "SSH_KEY_MASTER_SERVER"
  public_key = var.SSH_KEY_MASTER_SERVER
}