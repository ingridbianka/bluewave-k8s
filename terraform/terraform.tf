
terraform {
  required_version = ">= 1.0.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # version = ">= 3.66.0"
      version = "= 4.67.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.6.1"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.4.1"
    }

    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.4.0"
    }
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "3.6.0"
    }
  }

}