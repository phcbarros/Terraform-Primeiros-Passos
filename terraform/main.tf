terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# variables 
variable "region" {}

# Configure the DigitalOcean Provider
variable "do_token" {}

provider "digitalocean" {
  token = var.do_token
}

variable "ssh_key_name" {}

data "digitalocean_ssh_key" "ssh_key" {
  name = var.ssh_key_name
}

# Create a new Web Droplet

variable "droplet_image" {}
variable "droplet_name" {}
variable "droplet_size" {}

resource "digitalocean_droplet" "jenkins" {
  image    = var.droplet_image
  name     = var.droplet_name
  region   = var.region
  size     = var.droplet_size
  ssh_keys = [data.digitalocean_ssh_key.ssh_key.id]
}

variable "k8s_cluster_name" {}
variable "k8s_cluster_size" {}
variable "k8s_cluster_node_pool_name" {}
variable "k8s_cluster_node_pool_count" {}

resource "digitalocean_kubernetes_cluster" "k8s" {
  name   = var.k8s_cluster_name
  region = var.region
  # Grab the latest version slug from `doctl kubernetes options versions`
  version = "1.26.3-do.0"

  node_pool {
    name       = var.k8s_cluster_node_pool_name
    size       = var.k8s_cluster_size
    node_count = var.k8s_cluster_node_pool_count
  }
}

# obtém o ip da máquina virtual 
output "jenkins_ip" {
  value = digitalocean_droplet.jenkins.ipv4_address
}

# cria o arquivo kube_config local
resource "local_file" "kube_config" {
  content  = digitalocean_kubernetes_cluster.k8s.kube_config.0.raw_config
  filename = "kube_config.yaml"
}