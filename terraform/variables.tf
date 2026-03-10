variable "HCLOUD_API_TOKEN" {
  type = string
  description = "API token for Hetzner Cloud connection"
  sensitive = true
}

variable "SSH_KEY" {
  type = string
  description = "own ssh key"
  sensitive = true
}

variable "SSH_KEY_MASTER_SERVER" {
  type = string
  description = "master server ssh key"
  sensitive = true
}