terraform {
  /*backend "remote" {
    hostname     = "app.terraform.io"
    organization = "VictorPonceOG"

    workspaces {
      name = "development"
    }
  }*/
  required_version = "~> 1.10.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.83.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.5"
    }
  }
}