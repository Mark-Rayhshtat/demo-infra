terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.95.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.2"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.3.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.35.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.25.0"
    }
  }
}